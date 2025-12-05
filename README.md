# BIM 493 - Assignment 4 (Barcode Store Manager)

This Flutter application serves as a store inventory management system using a local SQLite database, developed for the Mobile Programming I course.

## Overview

The application utilizes **sqflite** for local data persistence. Key features include:
1.  **Search:** Query products by Barcode ID.
2.  **Create:** Add new products if the barcode is not found.
3.  **Manage:** Edit or Delete existing inventory items.

## Project Structure

* **`lib/main.dart`**: UI components, search logic, and input forms.
* **`lib/product_model.dart`**: `Product` class definition matching the database schema.
* **`lib/database_helper.dart`**: SQLite connection handling and CRUD operations.

## Database Schema

A single table, `ProductTable`, is used:
* **BarcodeNo**: Primary Key (String).
* **Stockinfo**: Optional (Nullable).
* **Price**: Automatically calculated (`UnitPrice` + `TaxRate`).

## Validation & Logic

* **Search Flow:** A dialog prompts creation if a searched barcode is missing.
* **Validation:** Required fields must be populated. Numeric values (Price, Tax, Stock) are validated to be non-negative. Duplicate barcodes are prevented.
* **Persistence:** Data is retagitined locally across application restarts.

## Setup Instructions

1.  Clone the repository.
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the application:
    ```bash
    flutter run
    ```

## Group Members

* Bahar Demirkan
* Emine Nur Güçlü
* Emirhan Temiz