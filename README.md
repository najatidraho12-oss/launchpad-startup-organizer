<div align="center">

# LaunchPad

### Startup Organizer Mobile Application

A Flutter application designed to help project owners and innovation teams  
structure ideas, organize tasks and track startup project progress.

<br/>

<img src="https://img.shields.io/badge/Flutter-7E9BBE?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-A9C6E3?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/SQLite-C5A8D8?style=for-the-badge&logo=sqlite&logoColor=white"/>

</div>

<br/>

---

## About the Project

**LaunchPad** is a mobile application developed with Flutter to provide a structured workspace for startup projects.

It helps users organize their ideas, manage tasks through a Kanban workflow, define priorities, visualize a project roadmap and monitor overall progress.

---

## Features

### Idea Management

Users can create and manage startup ideas with:

- Title and description
- Priority level: High, Medium or Low
- Category
- Creation date
- Search and filtering

Ideas can be added, edited or deleted directly from the application.

### Kanban Board

LaunchPad provides a simple Kanban workflow divided into three stages:

`Backlog` → `In Progress` → `Done`

Ideas can be moved between stages according to their current progress.

### Project Roadmap

The roadmap provides a visual overview of:

- Project objectives
- Main features
- Deadlines
- Overall progress

### Statistics

The application includes graphical indicators for:

- Ideas by category
- Priority distribution
- Project progress

---

## Tech Stack

<div align="center">

| Technology | Usage |
|:---:|---|
| **Flutter** | Cross-platform mobile development |
| **Dart** | Application logic |
| **SQLite** | Local data persistence |

</div>

---

## Project Architecture

The source code is organized into separate layers to keep the application easier to maintain and extend.

```text
lib/
│
├── models/
├── providers/
├── services/
├── views/
└── widgets/
```

**Models**  
Defines the application's data structures.

**Providers**  
Handles state management and application logic.

**Services**  
Manages data access and application services.

**Views**  
Contains the main application screens.

**Widgets**  
Contains reusable user interface components.

---

## Application Workflow

```text
Create an Idea
      ↓
Set Category & Priority
      ↓
Add to Backlog
      ↓
Move to In Progress
      ↓
Complete the Task
      ↓
Track Project Progress
```

---

## Author

<div align="center">

**Najat ID Raho**

Computer Engineering Student — ENIAD

<br/>

<a href="https://www.linkedin.com/in/najat-id-raho-b05a25360/">
  <img src="https://img.shields.io/badge/LinkedIn-8FAFD1?style=for-the-badge&logo=linkedin&logoColor=white"/>
</a>

<a href="https://github.com/najatidraho12-oss">
  <img src="https://img.shields.io/badge/GitHub-C5A8D8?style=for-the-badge&logo=github&logoColor=white"/>
</a>

</div>

<br/>

---

<div align="center">

<sub>Developed as part of my Computer Engineering projects.</sub>

</div>
