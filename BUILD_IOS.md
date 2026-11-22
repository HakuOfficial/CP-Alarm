# CP Alarm trên iPhone và iPad

Tên ứng dụng **CP Alarm**. Bundle ID mặc định `com.kuda.cpalarm`. Mục tiêu iOS 17 trở lên. Dùng Xcode 26 hoặc mới hơn vì mã Swift tham chiếu AlarmKit. iOS 17–18 chạy cùng binary và dùng thông báo cục bộ.

## Chạy trên Mac

1. Cài Flutter stable từ [Flutter SDK](https://docs.flutter.dev/install), tối thiểu 3.44 cho plugin thông báo. Cài Xcode, bộ công cụ dòng lệnh, CocoaPods và Ruby gem xcodeproj. Chạy `flutter doctor -v`.
2. Mở Terminal ở thư mục có `pubspec.yaml`. Chạy các lệnh dưới đây. Bootstrap tạo **ios/Runner.xcodeproj** từ template chính thức của SDK đang cài rồi cấu hình iOS 17, Swift, tên ứng dụng, quyền AlarmKit, icon, splash và âm thanh. Không cần dựng Runner bằng tay.
3. Chọn thiết bị do `flutter devices` liệt kê. Dùng `flutter run -d <id>` để chạy app với dữ liệu thật. Lần đầu sẽ có lịch trống để anh tự nhập.

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcodebuild -downloadPlatform iOS
gem install --user-install xcodeproj
bash tool/bootstrap_ios.sh
flutter analyze
flutter test
open -a Simulator
flutter devices
```

Đối chiếu giao diện với dữ liệu giống mẫu bằng `flutter run --dart-define=CP_DEMO=true`. Chế độ này dùng tệp SQLite riêng. Nên dùng Simulator cho bản minh họa. Thay đổi cờ này trên cùng một bản cài vẫn dùng chung quyền iOS và hàng đợi thông báo của bundle.

## Cài trên iPhone cá nhân

Kết nối iPhone với Mac, cho phép tin cậy và bật Developer Mode trên điện thoại. Mở `ios/Runner.xcworkspace` sau khi Flutter đã chuẩn bị các phụ thuộc. Trong **Runner → Signing & Capabilities**, chọn Apple Team và bật **Automatically manage signing**. Dùng bundle ID anh sở hữu. Có thể đặt `export BUNDLE_ID=vn.tencongty.cpalarm` trước khi chạy bootstrap. Mở Xcode Settings → Accounts để thêm Apple Account.

Personal Team miễn phí cho phép thử trên thiết bị cá nhân. Provisioning profile hết hạn sau 7 ngày, khi đó cần build và cài lại. TestFlight và App Store yêu cầu tư cách thành viên Apple Developer Program. [Apple Developer Account](https://developer.apple.com/help/account/basics/about-your-developer-account/)

## Xuất IPA

Đăng ký App ID trùng bundle ID, chọn team, tạo bản ghi ứng dụng trên App Store Connect và hoàn tất chứng chỉ ký phân phối trên Mac. Từ thư mục gốc chạy:

```bash
flutter build ipa --release --build-name=1.0.0 --build-number=1
```

Archive ở `build/ios/archive/`, IPA ở `build/ios/ipa/`. Có thể mở archive trong Xcode Organizer để Validate App và Distribute App. Với từng lần gửi TestFlight, tăng build number. [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios)

## GitHub Actions

Đưa **nội dung** thư mục CP_Alarm vào gốc repository, gồm cả `.github/workflows/ios.yml`. Push lên main chạy phân tích, unit/widget test và build simulator trên macOS. Muốn xuất IPA, đặt repository variable `BUNDLE_ID` đúng App ID, tạo ba Actions secrets sau và chạy workflow **CP Alarm iOS → Run workflow → signed**.

| Secret | Giá trị |
| --- | --- |
| APPLE_P12_B64 | Apple Distribution certificate cùng private key xuất thành .p12, mã hóa base64 |
| APPLE_P12_PASSWORD | Mật khẩu của .p12 |
| APPLE_PROFILE_B64 | App Store provisioning profile của App ID, mã hóa base64 |

Trên macOS có thể dùng `base64 -i distribution.p12 | pbcopy` để nhập vào secret tương ứng. Workflow đọc team và tên profile từ profile đã ký, tạo keychain tạm, xuất IPA, dọn keychain và trả về artifact **CP-Alarm-IPA**. Việc phát hành lên TestFlight là bước riêng. Lưu pubspec.lock do `flutter pub get` tạo vào repository sau lần giải phụ thuộc thành công.

## Kiểm tra trên máy thật

- iOS 26, tạo báo thức sau 2 phút, cho phép AlarmKit rồi khóa máy với Silent và Focus. Thử tắt và nhắc lại sau 5 phút trên giao diện của hệ thống. Khi mở app, thử trượt để tắt và VoiceOver.
- Trên iOS 17/18 hoặc khi từ chối quyền AlarmKit, cho phép thông báo và âm thanh, kiểm tra các mốc 30/10/5. Chế độ im lặng và Focus có thể chặn âm fallback. Bật lại quyền bị từ chối trong Cài đặt iPhone.
- Đặt nhiều báo thức trùng tuần. Ứng dụng chọn tối đa 64 mốc gần nhất và lập lịch lại khi mở/sửa. Các lần lặp được trải trong 14 ngày tới. Cần mở lại app để nạp thêm mốc. iOS quản lý lịch khi ứng dụng đóng. Màn hình Flutter chỉ xuất hiện khi app đang hoạt động hoặc mở từ thông báo.
- Giờ luyện là tổng thời lượng buổi đã đánh dấu hoàn thành. Trong lịch, chạm buổi đã diễn ra để đánh dấu. Heatmap tính số bài AC khác nhau trong ngày địa phương. Rating của từng OJ được vẽ riêng.

## Kết quả khảo sát ngày 22/11/2026

| OJ | Đọc được từ môi trường khảo sát | Chưa xác nhận được dữ liệu trả về |
| --- | --- | --- |
| Codeforces | user.info, user.rating, contest.list | user.status |
| AtCoder | kenkoooo.com/atcoder/resources/contests.json | API submissions và atcoder.jp/users/tourist/history/json |
| VNOJ | Chưa xác nhận route dữ liệu | /api/v2/user/ntucoder, /api/v2/submissions, /user/ntucoder, /user/ntucoder/solved, /submissions/ntucoder/ |
| ChuyênTin | oj.chuyentin.net/user/admin trả HTML và tổng số bài | API user, submissions, trang solved và trang submissions theo username |

Các kết quả trên đến từ truy xuất web, có thể qua bộ nhớ đệm. Phép thử HTTP trực tiếp từ máy Windows gặp lỗi DNS. Test fixture kiểm tra hợp đồng dữ liệu mẫu. Lỗi đồng bộ hiển thị ở màn tài khoản và không thay thế dữ liệu đã lưu.

[Apple AlarmKit](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit) · [Plugin thông báo](https://pub.dev/packages/flutter_local_notifications) · [Codeforces API](https://codeforces.com/apiHelp) · [AtCoder Problems API](https://github.com/kenkoooo/AtCoderProblems/blob/master/doc/api.md)
