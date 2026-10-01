import PhotosUI
import SwiftUI
import UIKit

struct EditorView: View {
    @Environment(\.openURL) private var openURL
    @State private var store = EditorStore()
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var isPhotoPickerPresented = false
    @State private var isAccessDeniedAlertPresented = false

    private let borderColors: [BorderColorOption] = [
        BorderColorOption(id: "white", modelColor: .white, displayColor: .white),
        BorderColorOption(
            id: "warm-gray",
            modelColor: try! RGBAColor(red: 222 / 255, green: 216 / 255, blue: 205 / 255),
            displayColor: .warmGray
        ),
        BorderColorOption(
            id: "charcoal",
            modelColor: try! RGBAColor(red: 31 / 255, green: 33 / 255, blue: 31 / 255),
            displayColor: .charcoal
        ),
        BorderColorOption(
            id: "clay",
            modelColor: try! RGBAColor(red: 214 / 255, green: 95 / 255, blue: 54 / 255),
            displayColor: .clay
        ),
        BorderColorOption(
            id: "sage",
            modelColor: try! RGBAColor(red: 138 / 255, green: 154 / 255, blue: 142 / 255),
            displayColor: .sage
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    preview
                    photoStrip
                    controls
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .toolbarBackground(Color.panelBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Label("Whiteborders", systemImage: "square.inset.filled")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.exportSelectedPhoto() }
                    } label: {
                        if store.isExporting {
                            ProgressView()
                        } else {
                            Label("Save photo", systemImage: "square.and.arrow.down")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.charcoal)
                    .disabled(store.selectedResource == nil || store.isExporting)
                }
            }
        }
        .tint(.clay)
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $selectedPickerItems,
            matching: .images
        )
        .onChange(of: selectedPickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importPhotos(from: items) }
        }
        .alert("Photo Access Needed", isPresented: $isAccessDeniedAlertPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
        } message: {
            Text("Allow Whiteborders to read photos in Settings so you can choose images to frame.")
        }
        .alert("Couldn’t Import Photo", isPresented: importErrorBinding) {
            Button("OK", role: .cancel) { store.clearImportError() }
        } message: {
            Text(store.importErrorMessage ?? "The selected photo could not be imported.")
        }
        .alert(exportAlertTitle, isPresented: exportNoticeBinding) {
            Button("OK", role: .cancel) { store.clearExportNotice() }
        } message: {
            Text(exportAlertMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT PHOTO")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondaryText)
                Text(store.selectedResource == nil ? "No photo selected" : "Imported photo")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.primaryText)
            }
            Spacer()
            Text("1:1")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.top, 12)
    }

    private var preview: some View {
        GeometryReader { geometry in
            let side = geometry.size.width

            ZStack {
                Color.panelBackground
                previewImage
            }
            .frame(width: side, height: side)
            .shadow(color: .black.opacity(0.16), radius: 24, y: 12)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var photoStrip: some View {
        HStack(spacing: 10) {
            if !store.orderedResources.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 10) {
                        ForEach(store.orderedResources) { resource in
                            Button {
                                Task { await store.selectPhoto(resource.id) }
                            } label: {
                                if let image = UIImage(contentsOfFile: resource.fileURL.path) {
                                    thumbnail(
                                        Image(uiImage: image),
                                        isSelected: store.selectedPhotoID == resource.id
                                    )
                                }
                            }
                            .accessibilityLabel("Select imported photo")
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity)
            }

            addPhotoButton

            if store.orderedResources.isEmpty {
                Spacer()
            }
        }
        .frame(height: 58)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addPhotoButton: some View {
        Button {
            Task { await requestPhotoAccess() }
        } label: {
            Group {
                if store.isRequestingAuthorization || store.isImportingPhotos {
                    ProgressView()
                } else {
                    Image(systemName: "plus")
                }
            }
                .frame(width: 54, height: 54)
                .background(Color.panelBackground)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color.secondaryText)
                }
        }
        .accessibilityLabel("Add photos")
        .disabled(store.isRequestingAuthorization || store.isImportingPhotos)
    }

    private var controls: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                HStack {
                    Text("Border")
                        .font(.headline)
                    Spacer()
                    Text("\(borderPercentage, specifier: "%.0f")%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color.secondaryText)
                }
                Slider(
                    value: borderPercentageBinding,
                    in: 2...16,
                    step: 1,
                    onEditingChanged: { isEditing in
                        guard !isEditing else { return }
                        Task {
                            await store.setBorderFraction(
                                borderPercentage / 100,
                                isContinuous: false
                            )
                        }
                    }
                )

                HStack(spacing: 12) {
                    ForEach(borderColors) { option in
                        Button {
                            Task { await store.setBorderColor(option.modelColor) }
                        } label: {
                            Circle()
                                .fill(option.displayColor)
                                .frame(width: 34, height: 34)
                                .overlay {
                                    Circle().stroke(Color.black.opacity(0.12))
                                }
                                .overlay {
                                    if selectedBorderColor == option.modelColor {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(
                                                option.displayColor == .charcoal ? .white : .primaryText
                                            )
                                    }
                                }
                        }
                        .accessibilityLabel("Select border color")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task { await store.exportAllPhotos() }
            } label: {
                Group {
                    if store.isExporting {
                        ProgressView()
                    } else {
                        Label("Save all photos", systemImage: "square.and.arrow.down")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.charcoal)
            .disabled(store.isExporting)
        }
        .padding(18)
        .background(Color.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .disabled(store.selectedResource == nil)
    }

    private func requestPhotoAccess() async {
        await store.requestPhotoAccess()

        if store.canReadPhotos {
            isPhotoPickerPresented = true
        } else if store.accessWasDenied {
            isAccessDeniedAlertPresented = true
        }
    }

    @ViewBuilder
    private var previewImage: some View {
        if let image = store.renderedPreview {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Selected imported photo")
        } else if store.selectedResource != nil {
            ProgressView("Rendering photo…")
        } else {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 34, weight: .light))
                Text("No images imported yet")
                    .font(.headline)
                Text("Tap the plus button below to choose photos.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primaryText)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .combine)
        }
    }

    private func thumbnail(_ image: Image, isSelected: Bool) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isSelected ? Color.clay : .clear, lineWidth: 3)
            }
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { store.importErrorMessage != nil },
            set: { isPresented in
                if !isPresented { store.clearImportError() }
            }
        )
    }

    private var borderPercentage: Double {
        (store.selectedPhoto?.border.fraction ?? 0.07) * 100
    }

    private var selectedBorderColor: RGBAColor {
        store.selectedPhoto?.border.color ?? .white
    }

    private var borderPercentageBinding: Binding<Double> {
        Binding(
            get: { borderPercentage },
            set: { value in
                Task {
                    await store.setBorderFraction(value / 100, isContinuous: true)
                }
            }
        )
    }

    private var exportNoticeBinding: Binding<Bool> {
        Binding(
            get: { store.exportNotice != nil },
            set: { isPresented in
                if !isPresented { store.clearExportNotice() }
            }
        )
    }

    private var exportAlertTitle: String {
        if case .some(.saved) = store.exportNotice { return "Photos Saved" }
        return "Couldn’t Save Photo"
    }

    private var exportAlertMessage: String {
        switch store.exportNotice {
        case let .saved(count):
            return count == 1
                ? "The finished photo was added to your Photos library."
                : "\(count) finished photos were added to your Photos library."
        case let .failed(message):
            return message
        case nil:
            return ""
        }
    }

    private func importPhotos(from items: [PhotosPickerItem]) async {
        var inputs: [PhotoImportInput] = []
        var pickerLoadFailed = false

        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    pickerLoadFailed = true
                    continue
                }
                inputs.append(
                    PhotoImportInput(
                        data: data,
                        preferredFileExtension: item.supportedContentTypes.first?.preferredFilenameExtension
                    )
                )
            } catch {
                pickerLoadFailed = true
            }
        }

        await store.importPhotos(inputs)
        if pickerLoadFailed { store.reportImportFailure() }
        selectedPickerItems.removeAll()
    }
}

private struct BorderColorOption: Identifiable {
    let id: String
    let modelColor: RGBAColor
    let displayColor: Color
}

private extension Color {
    static let appBackground = Color(red: 0.937, green: 0.929, blue: 0.91)
    static let panelBackground = Color(red: 0.973, green: 0.969, blue: 0.953)
    static let primaryText = Color(red: 0.137, green: 0.137, blue: 0.129)
    static let secondaryText = Color(red: 0.475, green: 0.471, blue: 0.451)
    static let charcoal = Color(red: 0.122, green: 0.129, blue: 0.122)
    static let clay = Color(red: 0.839, green: 0.373, blue: 0.212)
    static let sage = Color(red: 0.541, green: 0.604, blue: 0.557)
    static let warmGray = Color(red: 0.871, green: 0.847, blue: 0.804)
}

#Preview {
    EditorView()
}
