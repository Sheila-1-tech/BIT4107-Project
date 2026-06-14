# Gathiami Pharmacy App

A comprehensive Flutter application designed for pharmacy management. The system provides customers with an intuitive platform to browse medicines, upload prescriptions, place orders, and track deliveries. It also includes an administrative dashboard for inventory management, order processing, prescription review, and drug information lookup through the FDA API.

---

## Key Features

### Customer Application

* **Authentication:** Secure user registration and login functionality.
* **Home Dashboard:** Promotional banners, categorized products, popular medicines, and wellness bundles.
* **Medicine Details:** Product descriptions, pricing, stock availability, and add-to-cart functionality.
* **Prescription Upload:** Upload prescriptions using the camera, photo gallery, or PDF documents for pharmacist review.
* **Cart and Checkout:** Manage cart items, view order summaries, calculate delivery fees, and complete purchases.
* **Order Tracking:** Monitor order progress from placement to delivery through a timeline-based interface.
* **Profile Management:** Update delivery addresses, notification settings, and account preferences.
* **AI Assistant:** Integrated chatbot interface to assist users with general health-related inquiries.

### Admin Dashboard

* **Overview and Analytics:** Monitor revenue, pending orders, inventory levels, and low-stock alerts.
* **Order and Prescription Review:** Review, approve, reject, or process customer orders and prescriptions.
* **Inventory Management:** Perform Create, Read, Update, and Delete (CRUD) operations on medicine records stored in SQLite.
* **FDA Drug Lookup:** Search drug information using the openFDA API and import selected records into the local inventory.
* **SQLite Inspector:** View and manage database records directly through the administrative interface.

---

## Technology Stack

### Framework

* Flutter (Dart)

### State Management

* Provider
* Singleton pattern
* StreamController for reactive user interface updates

### Local Storage

* sqflite / sqflite_common_ffi_web
* shared_preferences

### Networking

* http package for API integration

### Media and File Handling

* video_player
* image_picker
* file_picker

---

## Getting Started

### Prerequisites

Ensure the following tools are installed:

* Flutter SDK (Version 3.0 or later)
* Dart SDK
* Visual Studio Code, Android Studio, or another compatible IDE

### Installation

#### Clone the Repository

```bash
git clone https://github.com/yourusername/gathiami-pharmacy.git
cd gathiami-pharmacy/pharmacy_app
```

#### Install Dependencies

```bash
flutter pub get
```

#### Run the Application

```bash
flutter run
```

The application supports Android, iOS, and Web platforms.

---

## Default Credentials

The application currently uses a demonstration authentication service.

### Administrator Account

**Email:** [admin@pharmacy.com](mailto:admin@pharmacy.com)
**Password:** admin123

Any other valid email and password combination will be treated as a customer account.

---

## Project Structure

* `lib/models/` – Data models such as Medicine, Order, Prescription, User, and DrugInfo.
* `lib/screens/` – User interface screens for customer and administrator workflows.
* `lib/services/` – Business logic, database services, state management, and API integrations.
* `lib/widgets/` – Reusable user interface components.

---

## License

This project is licensed under the MIT License.
