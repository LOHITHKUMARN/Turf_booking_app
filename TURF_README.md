# Turf — A Comprehensive Multi-Role Turf Management & Booking Ecosystem

Turf is a production-grade, full-stack ecosystem designed to streamline the management of sports venues. It features a sophisticated architecture comprising **four dedicated Flutter mobile applications** (Customer, Owner, Staff, Admin) synchronized through a centralized **Node.js/MongoDB REST API**, enabling real-time slot booking, staff management, and financial analytics.

---

## 📄 Resume Blurb (Copy/Paste)

**Turf | Lead Developer | [Date]**
*   Engineered a high-performance multi-app ecosystem for sports venue management, including **four specialized Flutter applications** for Customers, Owners, Staff, and Administrators.
*   Developed a scalable **Node.js / Express** backend with **MongoDB (Mongoose)** to manage complex business logic for real-time slot scheduling (3,000+ entries) and automated payout processing.
*   Implemented a cross-functional staff management system featuring **digital attendance**, maintenance tracking, incident reporting, and owner-to-staff internal announcements.
*   Designed a secure user experience with **JWT authentication**, **Bcrypt** hashing, and role-based access control (RBAC).
*   Built a mobile-first UI with **Provider** for state management, featuring dynamic carousels, image uploads (Multer), and real-time QR-based booking confirmation.
*   **Tech Stack:** Flutter, Dart, Node.js, Express, MongoDB, JWT, Provider, Mongoose, Zod.

---

## ✨ System Architecture & Features

### 👤 Customer App (B2C)
*   **Dynamic Booking:** Real-time slot availability check and instant reservation.
*   **Review System:** Community-driven feedback and rating system for venues.
*   **User Profiles:** Secure management of user data and booking history.

### 🏟️ Owner App (B2B)
*   **Venue Management:** Direct control over turf details, images, and active slots.
*   **Financial Dashboard:** Comprehensive analytics for revenue tracking and payout management.
*   **Team Oversight:** Monitoring staff activity and broadcasting internal announcements.

### 👷 Staff App (Operations)
*   **Shift Management:** Digital attendance tracking and shift verification.
*   **Quality Control:** Integrated maintenance and incident reporting modules for venue upkeep.
*   **Operations Feed:** Real-time access to owner announcements and operational updates.

### 🌐 Admin App (Global)
*   **Oversight Hub:** Global management of all users, owners, and registered venues.

---

## 🛠️ Technical Stack

### **Backend (The Core)**
*   **Runtime:** Node.js (Express framework)
*   **Database:** MongoDB Atlas (Mongoose ORM)
*   **Security:** JWT-based Auth, Bcrypt hashing, **Helmet** (HTTP headers), **Zod** (Data validation)
*   **File Handling:** **Multer** for cloud/local storage of turf and profile images.

### **Mobile (Client Layer)**
*   **Framework:** Flutter (SDK 3.8.0+)
*   **State Management:** Provider
*   **Packages:** http (REST API), Flutter Spinkit, Shared Preferences, Image Picker, Carousel Slider.
*   **UI/UX:** Modern Flutter design with custom themes and Google Fonts (Inter).

---

## 🏗️ Core Business Logic

1.  **Slot Engine:** Implements a dynamic slot-generation algorithm that prevents double-bookings across the ecosystem in real-time.
2.  **Role-Based Security:** A unified API with middleware-enforced role verification (isOwner, isAdmin, isStaff) ensuring data integrity across distinct apps.
3.  **Operational Workflow:** A closed-loop system where issues reported in the Staff app trigger notifications/updates in the Owner app, closing the feedback gap for maintenance and incidents.

---

## 🚀 Installation & Deployment

### **Backend**
1.  Navigate to `backend/` directory.
2.  Install dependencies: `npm install`.
3.  Configure `.env` with `MONGO_URI` and `JWT_SECRET`.
4.  Run the API: `npm run dev`.

### **Mobile Apps**
1.  Navigate to the specific app directory (`turf_customer`, `turf_owner`, etc.).
2.  Get packages: `flutter pub get`.
3.  Direct the API endpoint to your backend host.
4.  Build the APK: `flutter build apk --split-per-abi`.

---

*Turf was designed to demonstrate complex multi-role system integration, real-time data synchronization at scale, and the ability to build and manage a diverse suite of applications under a single unified backend.*
