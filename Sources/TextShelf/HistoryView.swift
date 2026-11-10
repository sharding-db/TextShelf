import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: ClipboardModel
    let onCopy: (String) -> Void
    let onQuit: () -> Void
    @State private var previewedText: String?

    private var preview: String? {
        if let previewedText, model.items.contains(previewedText) { return previewedText }
        return model.items.first
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text("TextShelf").font(.headline)
                    Text("最近复制的文本").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(model.items.count) / 15")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(.quaternary, in: Capsule())
            }
            .padding(16)

            Divider()
            if model.items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clipboard").font(.system(size: 30)).foregroundStyle(.tertiary)
                    Text("还没有复制记录").font(.system(size: 14, weight: .medium))
                    Text("复制一段文本后，会显示在这里")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).frame(height: 180)
            } else {
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(Array(model.items.enumerated()), id: \.element) { index, text in
                            Button { onCopy(text) } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Text(String(format: "%02d", index + 1))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 22).padding(.top, 3)
                                    Text(rowPreview(text))
                                        .font(.system(size: 12))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary).padding(.top, 3)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 9)
                                .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                                .contentShape(Rectangle())
                                .background(
                                    preview == text ? Color.accentColor.opacity(0.10) : .clear,
                                    in: RoundedRectangle(cornerRadius: 7)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("复制第 \(index + 1) 条：\(rowPreview(text))")
                            .onHover { hovering in if hovering { previewedText = text } }
                        }
                    }
                    .padding(8)
                }
                .frame(height: min(300, CGFloat(model.items.count) * 53 + 16))

                Divider()
                if let preview {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text("预览").font(.caption.weight(.medium))
                            Spacer()
                            Text("\(preview.count) 字符").font(.caption2).foregroundStyle(.secondary)
                        }
                        ScrollView {
                            Text(preview)
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .frame(height: 120)
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.65),
                                    in: RoundedRectangle(cornerRadius: 7))
                        .id(preview)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
            }

            if let error = model.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).padding(.bottom, 8)
            }
            Divider()
            HStack {
                Text("点击一条即可复制").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("退出", action: onQuit).buttonStyle(.plain)
                    .font(.caption).foregroundStyle(.secondary)
                    .accessibilityLabel("退出 TextShelf")
            }
            .padding(.horizontal, 16).padding(.vertical, 11)
        }
        .frame(width: 400)
    }

    private func rowPreview(_ text: String) -> String {
        let flattened = String(text.prefix(240))
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.joined(separator: " ")
        return flattened.isEmpty ? "（空白文本）" : flattened
    }
}
