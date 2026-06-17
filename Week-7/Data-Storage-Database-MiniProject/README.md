Week 7: Data Storage, Database Design and Mini Project


 Overview

This repository contains the Week 7 Mobile Application Development tasks focusing on data storage techniques, database design, and implementation of storage concepts in a mobile application.

The activities explore different storage methods used in mobile applications and demonstrate how databases can be designed and integrated into real-world mobile systems.

---

 Learning Objectives

By completing these tasks, the following objectives were achieved:

* Compare different mobile application storage methods.
* Understand the advantages and disadvantages of data storage techniques.
* Design a database structure for a mobile application.
* Implement data storage concepts in an existing mobile application.
* Generate and manage reports using stored data.

---

Repository Structure

```text
Week7-Data-Storage-Database-MiniProject/
│
├── README.md
│
├── Task1-Storage-Comparison/
│   └── storage_comparison.md
│
├── Task2-Database-Design/
│   └── database_design.md
│
└── Task3-Mini-Project/
    └── pharmacy_storage_implementation.md
```

---

Task 1: Storage Method Comparison

This task compares the major storage methods used in mobile application development.

Storage methods analyzed:

* Shared Preferences
* SQLite Database
* Firebase
* Internal Storage

The comparison focuses on:

* Advantages
* Disadvantages
* Appropriate use cases
* Performance considerations

Key Findings

| Storage Method     | Best Used For                      |
| ------------------ | ---------------------------------- |
| Shared Preferences | User settings and preferences      |
| SQLite             | Structured local database storage  |
| Firebase           | Cloud-based real-time applications |
| Internal Storage   | Private application files          |

---

 Task 2: Student Database Design

This task involved designing a database for a student management application.

Database Name

StudentManagementDB

Students Table

| Field Name   | Data Type |
| ------------ | --------- |
| student_id   | INTEGER   |
| name         | TEXT      |
| course       | TEXT      |
| year         | INTEGER   |
| phone_number | TEXT      |

Primary Key

student_id

 Database Structure

```text
Students
--------------------------------
student_id (PK)
name
course
year
phone_number
--------------------------------
```

The database structure ensures efficient storage and retrieval of student information.

---

Task 3: Pharmacy System Storage Implementation

As instructed to continue with the existing mobile application project, the concepts learned in Week 7 were applied to the Gathimaini Pharmacy Application.

Selected Storage Method

SQLite Database

 Reasons for Selecting SQLite

* Supports structured data storage.
* Works offline without internet connectivity.
* Suitable for inventory management.
* Fast retrieval of records.
* Easy integration with Android applications.

---

 Pharmacy Database Design

 Medicines Table

| Field Name    | Data Type |
| ------------- | --------- |
| medicine_id   | INTEGER   |
| medicine_name | TEXT      |
| price         | REAL      |
| quantity      | INTEGER   |

Primary Key: medicine_id

---

 Orders Table

| Field Name    | Data Type |
| ------------- | --------- |
| order_id      | INTEGER   |
| medicine_id   | INTEGER   |
| customer_name | TEXT      |
| order_date    | TEXT      |

Primary Key: order_id

Foreign Key: medicine_id

---

Database Relationship

```text
Medicines
    │
    │ medicine_id
    ▼
Orders
```

One medicine can appear in multiple customer orders.



 Expected Outputs

The application should be able to:

Medicine Management

* Add medicines
* Update medicine details
* Delete medicines
* View available stock

Order Management

* Record customer orders
* View order history
* Track medicine sales

Reports

* Available stock report
* Low-stock medicines report
* Customer order report
* Inventory summary report

---

 Screenshots

Add screenshots demonstrating:

1. Application home screen
2. Medicine registration screen
3. Database records
4. Order management screen
5. Generated reports

Example structure:

```text
assets/screenshots/
├── home_screen.png
├── add_medicine.png
├── inventory_list.png
├── orders.png
└── reports.png
```



 Technologies Used

* Android Studio
* Java
* SQLite Database
* Git
* GitHub

---

Skills Demonstrated

* Database Design
* Mobile Data Storage
* SQLite Implementation
* Report Generation
* Mobile Application Development
* GitHub Documentation

---
Conclusion

Week 7 provided practical experience in managing mobile application data using different storage mechanisms. SQLite was selected and applied within the Gathimaini Pharmacy Application due to its reliability, offline functionality, and ability to efficiently manage structured pharmacy records such as medicines and customer orders.

The implementation demonstrates how mobile applications can securely store, retrieve, and manage data while providing meaningful reports for decision-making.

---
 Author

Sheila Muriithi
BIT/2024/32455
Bachelor of Science in Information Technology
BIT4107 – Mobile Application Development
Week 7 Assignment
