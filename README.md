# KÈONHANH (KeoNhanh) - Nền Tảng Kết Nối & Ghép Kèo Sân Bóng Đá

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/Express.js-000000?style=for-the-badge&logo=express&logoColor=white" alt="Express" />
  <img src="https://img.shields.io/badge/Microsoft%20SQL%20Server-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white" alt="MSSQL" />
</p>

---

## 1. Giới Thiệu Dự Án

**Kèo Nhanh (KeoNhanh)** là ứng dụng di động hỗ trợ cộng đồng bóng đá phong trào:
- **Tìm đối giao lưu:** Dễ dàng tìm đội bạn cùng trình độ, cùng khu vực và khung giờ thi đấu phù hợp.
- **Tuyển quân & Tìm đội:** Cầu thủ tự do dễ dàng tìm kiếm câu lạc bộ; Đội trưởng tìm kiếm nhân tố bổ sung cho đội hình.
- **Ghim sân & Định vị:** Hỗ trợ tìm kiếm sân bóng qua bản đồ OpenStreetMap, định vị tọa độ GPS chính xác.
- **Giao tiếp nội bộ:** Kênh trò chuyện nhóm (Team Chat) riêng biệt cho từng đội bóng để thông báo và thảo luận chiến thuật.

---

## 2. Công Nghệ Sử Dụng (Tech Stack)

### Frontend (Mobile App)
- **Framework:** Flutter (SDK ^3.13.2, Dart 3)
- **Routing:** GoRouter (ShellRoute, Bottom Navigation Bar)
- **UI Design:** Material 3, Flutter Library Icons

### Backend (RESTful API)
- **Runtime:** Node.js (v18+)
- **Framework:** Express.js
- **Database:** Microsoft SQL Server 2016+

---

## 3. Thiết Kế Cơ Sở Dữ Liệu (ERD & Database Schema)

Hệ thống sử dụng cơ sở dữ liệu quan hệ **Microsoft SQL Server** (Không sử dụng SQLite):

| Bảng | Chức năng | Khóa chính | Khóa ngoại chính |
| :--- | :--- | :--- | :--- |
| **`Users`** | Tài khoản đăng nhập, mật khẩu băm, vai trò (`player`, `captain`, `admin`) | `Id` | Không có |
| **`User_profiles`** | Hồ sơ cầu thủ, vị trí, khu vực, trạng thái tìm đội | `Id` | `UserId` $\rightarrow$ `Users(Id)` |
| **`Teams`** | Thông tin đội bóng, logo, cấp độ, trạng thái tuyển quân | `Id` | `CaptainId` $\rightarrow$ `Users(Id)` |
| **`TeamPlayers`** | Bảng liên kết nhiều-nhiều giữa Đội bóng và Cầu thủ | `Id` | `TeamId` $\rightarrow$ `Teams(Id)`, `UserProfileId` $\rightarrow$ `User_profiles(Id)` |
| **`Matches`** | Thông tin kèo đấu, thời gian, tên sân, địa chỉ, tọa độ GPS, trạng thái | `Id` | `CreatorTeamId`, `MatchedWithTeamId` $\rightarrow$ `Teams(Id)` |
| **`JoinRequests`** | Đơn xin gia nhập đội của cầu thủ tự do | `Id` | `RequesterId` $\rightarrow$ `User_profiles(Id)`, `TeamId` $\rightarrow$ `Teams(Id)` |
| **`Invitations`** | Lời mời cầu thủ gia nhập đội từ đội trưởng | `Id` | `TeamId` $\rightarrow$ `Teams(Id)`, `UserId` $\rightarrow$ `Users(Id)` |
| **`Messages`** | Tin nhắn thảo luận nội bộ đội bóng | `Id` | `TeamId` $\rightarrow$ `Teams(Id)`, `SenderId` $\rightarrow$ `Users(Id)` |

---

## 4. Cấu Trúc Thư Mục Dự Án (Project Structure)

```text
keonhanh/
├── keonhanh.sql                # Script thiết kế Database & Tables
├── README.md                   # Tài liệu thiết kế hệ thống
└── ui/                         # Source code ứng dụng Flutter Mobile
    ├── lib/
    │   ├── config/             # Cấu hình app
    │   ├── models/             # Data models
    │   ├── screens/            # Màn hình giao diện (Auth, Home, Profile...)
    │   ├── utils/              # Tiện ích HTTP & formatters
    │   └── main.dart           # Điểm khởi chạy ứng dụng & Navigation
    └── pubspec.yaml
```
