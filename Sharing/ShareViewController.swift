//
//  ShareViewController.swift
//  Sharing
//
//  Created by Paul Griffiths on 18/9/25.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers
import Combine
import SwiftData

@MainActor
final class ShareModel: ObservableObject {
    @Published var text: String = ""
}

@objc(ShareViewController)
class ShareViewController: UIViewController {

    // MARK: - Purpose
    // Extract shared content (plain text first, then URL) from the NSItemProvider,
    // show it in a SwiftUI editor, save one OutboxItem to SwiftData, then dismiss.

    // MARK: - UI & State
    private var hostingController: UIHostingController<AnyView>?
    private var didExtract = false  // Ensure we only extract data once
    private let model = ShareModel()
    private let modelContainer: ModelContainer = SharedModelContainer()
    private var didSave = false  // Ensure we only save once

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ensure we only read from the extension context once.
        guard !didExtract else { return }
        didExtract = true

        // Ensure access to extensionItem and itemProvider
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = extensionItem.attachments?.first
        else {
            close()
            return
        }

        // Optional page title from the host app (Safari often provides this)
        let pageTitle: String? = extensionItem.attributedContentText?.string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Prefer plain text: many apps (Notes, Mail) share as plain text.
        let plainId = UTType.plainText.identifier
        if itemProvider.hasItemConformingToTypeIdentifier(plainId) {
            loadPlainText(from: itemProvider)
            return
        }

        // Fallback to URL if no plain text was provided.
        let urlId = "public.url"
        if itemProvider.hasItemConformingToTypeIdentifier(urlId) {
            loadURL(from: itemProvider, pageTitle: pageTitle)
            return
        }

        // Nothing we support
        close()
    }

    // MARK: - Helpers
    /// For URL shares: format according to user profile preference (Roam-style link or default).
    private func formatURLText(urlString: String, pageTitle: String?) -> String {
        // Trim the provided title for neatness
        let cleanedTitle = pageTitle?.trimmingCharacters(in: .whitespacesAndNewlines)

        // Load the single UserProfile to read the share-format preference
        let modelContext = ModelContext(self.modelContainer)
        let profile: UserProfile? = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first

        if let profile, profile.shareFormatLinks {
            // Roam-style link: [TEXT](URL). If no title, use URL as visible text.
            let visible = (cleanedTitle?.isEmpty == false) ? cleanedTitle! : urlString
            return clamp("[\(visible)](\(urlString))")
        }

        // Default formatting: TITLE then URL (if a title exists). Otherwise just URL.
        if let title = cleanedTitle, !title.isEmpty, title != urlString {
            return clamp(title + " - " + urlString)
        } else {
            return clamp(urlString)
        }
    }

    /// Clamp overly long strings (protects TextEditor and database from huge payloads like full HTML).
    private func clamp(_ s: String, limit: Int = 50_000) -> String {
        if s.count <= limit { return s }
        let endIndex = s.index(s.startIndex, offsetBy: limit)
        return String(s[..<endIndex])
    }

    /// Load plain text from an item provider; sets model.text (no URL appended) or closes on failure.
    private func loadPlainText(from provider: NSItemProvider) {
        let plainId = UTType.plainText.identifier
        provider.loadItem(forTypeIdentifier: plainId, options: nil) { [weak self] (provided, error) in
            DispatchQueue.main.async {
                guard let self else { return }
                if error != nil { self.close(); return }
                if let s = provided as? String {
                    self.model.text = self.clamp(s)
                } else if let d = provided as? Data, let s = String(data: d, encoding: .utf8) {
                    self.model.text = self.clamp(s)
                } else {
                    self.close()
                }
            }
        }
    }

    /// Load a URL as text from an item provider; sets model.text or closes on failure.
    private func loadURL(from provider: NSItemProvider, pageTitle: String?) {
        let urlId = "public.url"
        provider.loadItem(forTypeIdentifier: urlId, options: nil) { [weak self] (urlItem, error) in
            DispatchQueue.main.async {
                guard let self else { return }
                if error != nil { self.close(); return }
                if let url = urlItem as? URL {
                    self.model.text = self.formatURLText(urlString: url.absoluteString, pageTitle: pageTitle)
                } else if let nsurl = urlItem as? NSURL {
                    self.model.text = self.formatURLText(urlString: (nsurl as URL).absoluteString, pageTitle: pageTitle)
                } else if let s = urlItem as? String, let u = URL(string: s) {
                    self.model.text = self.formatURLText(urlString: u.absoluteString, pageTitle: pageTitle)
                } else if let d = urlItem as? Data, let s = String(data: d, encoding: .utf8), let u = URL(string: s) {
                    self.model.text = self.formatURLText(urlString: u.absoluteString, pageTitle: pageTitle)
                } else {
                    self.close()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let root = ShareView(model: model, onPost: { [weak self] in
            guard let self else { return }
            if self.didSave { return }
            self.didSave = true
            Task { @MainActor in
                let modelContext = ModelContext(self.modelContainer)
                let text = self.model.text.trimmingCharacters(in: .whitespacesAndNewlines)
                // Trim whitespace-only shares; nothing meaningful to persist.
                if text.isEmpty { self.close(); return }
                let item = OutboxItem(content: text)
                modelContext.insert(item)
                do { try modelContext.save() }
                catch { }
                self.close()
            }
        })
        let rootView = AnyView(root.modelContainer(modelContainer))

        let hostingController = UIHostingController(rootView: rootView)
        self.hostingController = hostingController
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)

        NotificationCenter.default.addObserver(forName: NSNotification.Name("Close"), object: nil, queue: .main) { [weak self] _ in
            self?.close()
        }
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
