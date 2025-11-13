# BCA College Management System - Exam Module

A comprehensive Flutter-based college management system with a focus on exam management. This module provides functionality for administrators, teachers, and students to manage and participate in the examination process effectively.

## Features

### Admin Features
- Create and manage exams with detailed information:
  - Exam name, class, year, subjects
  - Total marks, date, time, and duration
  - Exam type (Online/Offline)
  - Status tracking (Upcoming, Ongoing, Completed)
- Generate and manage exam timetables
- View all exams and their current status
- Update exam status as needed

### Teacher Features
- View assigned exams for specific subjects
- Enter and submit student marks
- Automatic percentage calculation
- View submitted results

### Student Features
- View upcoming exam schedule
- Access exam results and performance analytics
- Track subject-wise progress
- View overall performance statistics

## Technical Implementation

### Database Structure (Firebase Firestore)
- **exams**: Stores exam details and configuration
- **exam_timetable**: Manages exam schedules
- **exam_results**: Stores student results and analytics

### Key Components
1. **Services**:
   - `ExamService`: Handles all exam-related operations
   - Firebase integration for data persistence
   - Real-time updates for exam status

2. **Screens**:
   - Admin: Exam creation and management interface
   - Teacher: Mark submission and result management
   - Student: Result viewing and performance tracking

3. **Models**:
   - Exam model for structured data handling
   - Result model for managing student performances

## Dependencies
- firebase_core: ^3.6.0
- cloud_firestore: latest
- intl: ^0.19.0
- fl_chart: ^0.70.2

## Getting Started

1. **Setup Firebase**:
   - Create a new Firebase project
   - Add your Flutter app to the project
   - Download and add the google-services.json file
   - Enable Firestore database

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

## Security Features
- Role-based access control
- Data validation at all levels
- Secure Firebase rules implementation
- Student data privacy protection

## Performance Features
- Efficient data loading with pagination
- Caching for better performance
- Optimized database queries
- Real-time updates where necessary

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
