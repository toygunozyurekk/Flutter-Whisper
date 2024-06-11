# Flutter Whisper Chatbot

This project aims to create a voice and text-based chatbot application using Flutter. Users can record their voice messages, process these messages via an API, and send text messages.

## Features

- Allows users to record and play voice messages.
- Sends recorded voice messages to a backend API and receives text transcription.
- Allows users to send text messages and receive responses.
- Displays messages in a chat interface.

## Requirements

- Flutter SDK
- Python 3.x (for backend)
- OpenAI API key

## Installation

### Flutter Project

1. **Clone or Download the Repository**
    ```bash
    git clone <repository_url>
    cd <repository_directory>
    ```

2. **Install the Required Dependencies**
    Run the following command to install the Flutter dependencies:
    ```bash
    flutter pub get
    ```

3. **Update the API Base URL**
    Open the `lib/services/api_service.dart` file and update the `_baseUrl` variable with your computer's IP address:
    ```dart
    final ApiService _apiService = ApiService('http://<your_computer_ip>:5000');
    ```

4. **Run the Application**
    Use the following command to run the application on your connected device or emulator:
    ```bash
    flutter run
    ```

### Backend

1. **Install the Required Python Packages**
    Run the following command to install the necessary Python packages:
    ```bash
    pip install flask flask-cors openai
    ```

2. **Create the `app.py` File**
    Create a file named `app.py` in your project directory and add the appropriate backend code to handle requests.

3. **Create a `.env` File**
    In the same directory as `app.py`, create a `.env` file and add your OpenAI API key:
    ```plaintext
    OPENAI_API_KEY=your_openai_api_key
    ```

4. **Start the Server**
    Run the following command to start the server:
    ```bash
    python app.py
    ```

## Usage

1. Run the application and send your messages via voice or text.
2. Voice messages are recorded, sent to the backend, and the text transcription is received.
3. Text messages are sent directly to the backend, and responses are received.

## Testing Device

The application was tested using the following device:

- **Device**: HUAWEI SNE-LX1
- **Android Version**: 10.0 ("Q")
- **Architecture**: arm64
