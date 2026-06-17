Week 6 Task 2: API Investigation Report
API Name: OpenWeatherMap API
1. Purpose of the API

The OpenWeatherMap API is a public web service that provides real-time and historical weather data for any location in the world. It allows developers to access weather information such as temperature, humidity, wind speed, weather conditions, and forecasts.

This API is commonly used in mobile and web applications to display live weather updates based on user location or searched cities. It is useful in applications such as travel apps, agriculture systems, logistics systems, and delivery services where weather conditions affect decision-making.

2. How the API Works

The OpenWeatherMap API follows a client-server architecture. The mobile or web application acts as the client, sending HTTP requests to the OpenWeatherMap server. The server processes the request and returns weather data in JSON format.

The most commonly used method is the GET request, which is used to retrieve weather information.
3. GET Request Example

Example of a GET request to retrieve weather data for London:
https://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_API_KEY

Explanation:
q=London → The city name being searched
appid → Unique API key used for authentication
4. Expected Response

The API returns data in JSON format. Example response:
{
  "weather": 
  [
    {
      "main": "Clouds",
      "description": "broken clouds"
    }
  ],
  "main": {
    "temp": 298.15,
    "humidity": 65,
    "pressure": 1012
  },
  "wind": {
    "speed": 3.5
  },
  "name": "London"
}

5. Application in Real Systems

The OpenWeatherMap API can be integrated into mobile applications to:

Display real-time weather updates to users
Help delivery apps adjust routes based on weather conditions
Assist agriculture apps in planning farming activities
Improve travel apps with weather forecasts

In mobile application development, APIs like this help apps communicate with external servers and retrieve dynamic data without storing everything locally.

Conclusion

The OpenWeatherMap API is a useful public API that demonstrates how mobile applications interact with external servers using HTTP requests. It plays an important role in modern application development by providing real-time weather data that can be integrated into various systems.
