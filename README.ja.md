# CameraModule

`CameraModule`は、SwiftUIで簡単に高機能なカメラを実装するためのSwift Packageです。
標準のUIコンポーネントを使って数行でカメラを導入できるほか、より柔軟なカスタムUIを構築することも可能です。

## 主な機能

- **SwiftUIネイティブ**: SwiftUIアプリにシームレスに統合できます。
- **写真撮影**: 高解像度での写真撮影に対応しています。
- **カメラ切り替え**: フロントカメラとバックカメラを簡単に切り替えられます。
- **スムーズなズーム**: ピンチ操作による直感的なズームが可能です。
- **広角カメラ対応**: デュアルカメラやトリプルカメラを搭載したデバイスでは、広角レンズへの切り替えをサポートします。
- **柔軟なカスタマイズ**: `CameraViewModel`と`CameraPreview`を直接利用して、独自のカメラUIを自由に構築できます。

## 動作環境

- iOS 12.0+

## インストール方法

Swift Package Manager を使用して、`CameraModule`をプロジェクトに簡単に追加できます。

1.  Xcodeでプロジェクトを開き、`File` > `Add Packages...` を選択します。
2.  検索バーにリポジトリのURLを貼り付けます。
    ```
    https://github.com/sugijotaro/CameraModule.git 
    ```
3.  `Add Package`ボタンをクリックして、プロジェクトにライブラリを追加します。

## 使い方

### 1. プロジェクトの設定

カメラを使用するには、`Info.plist`にカメラへのアクセス許可を求めるための説明文を追加する必要があります。

Xcodeのプロジェクト設定から `Info` タブを開き、`Custom iOS Target Properties` に以下のキーを追加してください。

- **Key**: `Privacy - Camera Usage Description`
- **Value**: `カメラを使用して写真を撮影します。` (または任意の適切な説明文)

### 2. 基本的な使い方 (デフォルトUI)

最も簡単な方法は、モジュールが提供する `CameraView` を使用することです。このビューには、撮影、カメラ切り替え、ズームなどの基本的なUIがすべて含まれています。

```swift
import SwiftUI
import CameraModule

struct MyContentView: View {
    @State private var capturedImage: UIImage?
    @State private var isShowingCamera = false

    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                Button("撮り直す") {
                    capturedImage = nil
                }
            } else {
                Button("カメラを起動") {
                    isShowingCamera = true
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraView { image in
                // 撮影された画像(UIImage)を受け取る
                self.capturedImage = image
                self.isShowingCamera = false
            }
        }
    }
}
```

### 3. カスタムUIでの使い方

より柔軟にUIをカスタマイズしたい場合は、`CameraViewModel` と `CameraPreview` を直接利用します。
これにより、プレビューのレイアウトやボタンの配置を自由にデザインできます。

以下の例では、カメラプレビューを画面中央に配置し、その下にカスタムボタンを置いています。

```swift
import SwiftUI
import CameraModule

struct CustomCameraView: View {
    // ViewModelを直接インスタンス化して使用
    @StateObject private var viewModel = CameraViewModel()
    
    // 撮影完了時のコールバック
    private var onImageCaptured: (UIImage) -> Void
    
    init(onImageCaptured: @escaping (UIImage) -> Void) {
        self.onImageCaptured = onImageCaptured
    }
    
    var body: some View {
        ZStack {
            // カメラプレビュー
            CameraPreview(viewModel: viewModel)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack {
                    // カメラ切り替えボタン
                    Button(action: {
                        viewModel.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // 撮影ボタン
                    Button(action: {
                        viewModel.capturePhoto()
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.capturedImage) { newImage in
            // 撮影された画像を処理
            if let image = newImage {
                onImageCaptured(image)
            }
        }
    }
}
```

## サンプルアプリ

このリポジトリの `/sample` ディレクトリには、`CameraModule`の基本的な使い方とカスタムUIでの使い方を示すデモアプリ `CameraDemoApp` が含まれています。

動作を確認するには、`sample/CameraDemoApp/CameraDemoApp.xcodeproj` をXcodeで開いてビルド・実行してください。（実機での実行が必要です）

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。