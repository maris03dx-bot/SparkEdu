# SparkEdu

### AI-Powered Smart Education Platform

**Smart India Hackathon 2026**

- **Problem Statement ID:** SIH26207
- **Problem Statement:** Student Innovation – Smart education, a concept that describes learning in digital age. It enables learners to learn more effectively, efficiently, flexibly and comfortably.
- **Theme:** Smart Education
- **Category:** Software
- **Team ID:** 155740
- **Team Name:** Auralogix

---

## 📌 About SparkEdu

SparkEdu is an AI-powered smart education platform designed to bring students, subject teachers, mentors, and academic administrators together in one integrated digital ecosystem.

The platform aims to make learning more personalized, organized, flexible, and accessible by combining AI-powered learning assistance with academic activities, communication, learning materials, quizzes, attendance, and academic progress tracking.

---

## 🎯 Problem

Students often depend on multiple disconnected platforms for learning, communication, quizzes, and academic activities.

This can make digital learning:

- Less organized
- Less personalized
- Difficult to track
- Dependent on multiple applications

Teachers and mentors may also have limited visibility into students' learning progress and learning gaps.

---

## 💡 Proposed Solution

SparkEdu provides an integrated smart education ecosystem where students can access learning support while teachers and mentors can monitor academic activities and provide guidance.

The platform combines:

- AI-powered doubt solving
- Personalized learning support
- AI-generated quizzes and MCQs
- Learning materials
- Academic progress tracking
- Attendance management
- Teacher-student communication
- Teacher and mentor dashboards
- Role-based access

---

## ✨ Key Features

### 🤖 SparkAI – AI Learning Assistant

Students can interact with SparkAI to:

- Ask academic doubts
- Get AI-generated explanations
- Receive subject-focused learning support
- Interact with an AI learning assistant

### 📝 AI Quiz & MCQ Generation

SparkEdu can use learning materials to generate practice questions and MCQs to support continuous learning and self-assessment.

### 📚 Personalized Learning

The platform is designed to identify areas where students need additional support and provide targeted learning recommendations.

### 📊 Academic Dashboard

Students can access academic information and monitor their learning activities and progress from a unified dashboard.

### 👨‍🏫 Teacher Dashboard

Subject teachers can manage academic activities and monitor student-related information.

### 👨‍💼 Mentor Dashboard

Mentors can monitor students and provide academic guidance and support.

### 💬 Communication

SparkEdu provides communication features that connect students, teachers, and mentors for academic interaction.

### 📱 Attendance Management

The platform includes QR-based attendance functionality for academic attendance tracking.

### 🔐 Role-Based Access

SparkEdu supports different user roles:

- Student
- Subject Teacher
- Mentor
- Associate Dean

Each role receives access to the appropriate features and dashboard.

---

## 🏗️ System Architecture

```text
                    SparkEdu
                       │
              Role-Based Login
                       │
        ┌──────────────┼──────────────┐
        │              │              │
     Student        Teacher         Mentor
        │              │              │
        └──────────────┼──────────────┘
                       │
                SparkEdu Platform
                       │
       ┌───────────────┼────────────────┐
       │               │                │
    SparkAI       Academic        Communication
       │           Tracking             │
       │               │                │
       └───────────────┼────────────────┘
                       │
              Firebase Backend
                       │
       ┌───────────────┼────────────────┐
       │               │                │
   Firebase Auth   Firestore        Storage