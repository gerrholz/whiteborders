import SwiftUI

struct EditorView: View {
    @State private var borderPercentage = 7.0
    @State private var showsCameraDetails = true
    @State private var selectedPhoto = 0
    @State private var borderColor = Color.white

    private let borderColors: [Color] = [.white, .warmGray, .charcoal, .clay, .sage]

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
                    Button("Save", systemImage: "square.and.arrow.down") {}
                        .buttonStyle(.borderedProminent)
                        .tint(.charcoal)
                }
            }
        }
        .tint(.clay)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT PHOTO")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondaryText)
                Text("Iceland coast")
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
            let inset = side * borderPercentage / 100

            ZStack {
                borderColor
                VStack(spacing: 12) {
                    Image("SampleCoast")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("A person walking on a windswept coast")

                    if showsCameraDetails {
                        cameraDetails
                    }
                }
                .padding(inset)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .shadow(color: .black.opacity(0.16), radius: 24, y: 12)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var cameraDetails: some View {
        HStack(spacing: 8) {
            Label("FUJIFILM X100VI", systemImage: "camera.aperture")
                .font(.caption2.weight(.bold))
            Spacer(minLength: 4)
            Text("23 mm · ƒ/4 · 1/500 s · ISO 160")
                .font(.caption2.monospacedDigit())
        }
        .foregroundStyle(Color.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private var photoStrip: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                Button {
                    selectedPhoto = index
                } label: {
                    Image("SampleCoast")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .overlay {
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(
                                    selectedPhoto == index ? Color.clay : .clear,
                                    lineWidth: 3
                                )
                        }
                }
                .accessibilityLabel("Select photo \(index + 1)")
            }

            Button {} label: {
                Image(systemName: "plus")
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                Slider(value: $borderPercentage, in: 2...16, step: 1)

                HStack(spacing: 12) {
                    ForEach(Array(borderColors.enumerated()), id: \.offset) { _, color in
                        Button {
                            borderColor = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 34, height: 34)
                                .overlay {
                                    Circle().stroke(Color.black.opacity(0.12))
                                }
                                .overlay {
                                    if borderColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(
                                                color == .charcoal ? .white : .primaryText
                                            )
                                    }
                                }
                        }
                        .accessibilityLabel("Select border color")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            Toggle(isOn: $showsCameraDetails) {
                Label("Camera details", systemImage: "camera.aperture")
                    .font(.headline)
            }

            Button {} label: {
                Label("Save photo", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.charcoal)
        }
        .padding(18)
        .background(Color.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
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

