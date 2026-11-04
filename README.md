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

---

## 5. Hướng Dẫn Cài Đặt & Chạy Backend

### Yêu cầu môi trường
- Node.js v18+ & npm
- Microsoft SQL Server 2016+

### Các bước khởi chạy
1. Mở SSMS hoặc Azure Data Studio, chạy file `keonhanh.sql` để tạo database và nạp dữ liệu mẫu.
2. Di chuyển vào thư mục backend:
   ```bash
   cd api
   npm install
   ```
3. Cấu hình file `.env` theo mẫu `.env.example`:
   ```env
   PORT=3000
   DB_USER=sa
   DB_PASSWORD=YourPassword123
   DB_SERVER=localhost
   DB_NAME=Keonhanh
   JWT_SECRET=supersecretkey
   ```
4. Chạy máy chủ:
   ```bash
   npm start
   # hoặc: npm run dev
   ```

---

## 6. Danh Sách RESTful API Endpoints

- **Auth:** `POST /api/auth/register`, `POST /api/auth/login`
- **Profiles & Players:** `GET /api/user-profiles/:userId`, `POST /api/user-profiles`, `GET /api/players`
- **Teams:** `GET /api/teams`, `GET /api/teams/:id`, `POST /api/teams`, `PATCH /api/teams/:teamId/recruiting`
- **Matches:** `GET /api/matches`, `POST /api/matches`, `POST /api/matches/:id/match`, `POST /api/matches/:id/unmatch`
- **Join Requests:** `GET /api/join-requests/captain/:userId`, `POST /api/join-requests`, `PATCH /api/join-requests/:id/approve`
- **Invitations:** `GET /api/invitations/user/:userId`, `POST /api/invitations`, `PATCH /api/invitations/:id/accept`
- **Messages:** `GET /api/messages/:teamId`, `POST /api/messages`
- **Notifications:** `GET /api/notifications`, `PATCH /api/notifications/:id/read`

---

## 7. Hướng Dẫn Cài Đặt & Chạy Frontend (Flutter Mobile)

1. Di chuyển vào thư mục `ui`:
   ```bash
   cd ui
   flutter pub get
   ```
2. Cấu hình `ui/.env`:
   ```env
   API_BASE_URL=http://localhost:3000
   # Android Emulator: http://10.0.2.2:3000
   ```
3. Khởi chạy ứng dụng:
   ```bash
   flutter run
   ```

---

## 8. Danh Sách Tài Khoản Dùng Thử (Demo Accounts)

Mật khẩu mặc định cho tất cả tài khoản: **`123456`**

| Tên đăng nhập | Mật khẩu | Vai trò | Mô tả |
| :--- | :--- | :--- | :--- |
| `admin_keonhanh` | `123456` | `admin` | Quản trị viên hệ thống |
| `nguyen_van_a` | `123456` | `captain` | Đội trưởng FC Sài Gòn Phố |
| `tran_thi_b` | `123456` | `captain` | Đội trưởng FC Hà Nội Titans |
| `le_van_c` | `123456` | `captain` | Đội trưởng FC Rồng Vàng Đà Nẵng |
| `dinh_trong_l` | `123456` | `player` | Cầu thủ tự do |
