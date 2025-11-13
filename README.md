# 🎓 BCA College Management System – Exam Module

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&size=24&duration=2200&pause=1000&color=00C3FF&center=true&vCenter=true&width=550&lines=Flutter+%2B+Firebase+Exam+Management;Admin+%7C+Teacher+%7C+Student+Modules;Real-Time+Updates+%7C+Analytics" />
</p>

A comprehensive **Flutter-based college management system** focused on the **Exam Module**.  
This module enables **Admins**, **Teachers**, and **Students** to manage and participate in the examination process efficiently.

---

# ✨ Features

## 👑 Admin Features
- Create and manage exams with detailed fields:
  - Exam name, class, year, subjects  
  - Total marks, date, time, duration  
  - Exam type (Online/Offline)  
  - Status (Upcoming, Ongoing, Completed)
- Generate and manage **exam timetables**
- View all exams with real-time status
- Update exam status anytime

---

## 👨‍🏫 Teacher Features
- View all assigned subject exams  
- Enter and submit student marks  
- Automatic **percentage calculation**  
- Access previously submitted results  

---

## 🎓 Student Features
- View upcoming exam schedule  
- Check results anytime  
- View subject-wise performance  
- Performance analytics & progress tracking  
- Overall performance statistics  

---

# 🛠️ Technical Implementation

## 🔥 Database Structure (Firebase Firestore)
- **exams** → Stores full exam details  
- **exam_timetable** → Manages all exam schedules  
- **exam_results** → Stores marks, percentages, and analytics  

---

## ⚙️ Key Components

### 1️⃣ Services
- `ExamService`  
- Real-time Firestore listeners  
- Role-based operations  

### 2️⃣ Screens
- **Admin**: Create, update exams; manage timetables  
- **Teacher**: Submit marks, manage results  
- **Student**: View results, analytics, schedules  

### 3️⃣ Models
- `ExamModel`  
- `ResultModel`  

---

# 📦 Dependencies

```yaml
firebase_core: ^3.6.0
cloud_firestore: latest
intl: ^0.19.0
fl_chart: ^0.70.2
