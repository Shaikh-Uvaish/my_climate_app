const express = require('express');

const app = express();

const PORT = 3000;
const API_KEY = 'PASTE_YOUR_OPENWEATHERMAP_API_KEY_HERE';
const BASE_URL = 'https://api.openweathermap.org/data/2.5';

// One function that both routes use.
// endpoint is either "weather" or "forecast"
async function getFromOpenWeather(endpoint, req, res) {
  const city = req.query.city;

  if (!city) {
    return res.status(400).json({ error: 'Please give a city' });
  }

  try {
    const url = `${BASE_URL}/${endpoint}?q=${encodeURIComponent(city)}&appid=${API_KEY}&units=metric`;
    const response = await fetch(url);
    const data = await response.json();

    if (response.status === 404) {
      return res.status(404).json({ error: `Couldn't find "${city}"` });
    }
    if (response.status === 401) {
      return res.status(401).json({ error: 'API key rejected. New keys can take up to 2 hours to activate.' });
    }
    if (!response.ok) {
      return res.status(500).json({ error: 'Weather service error' });
    }

    res.json(data);
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: 'Something went wrong' });
  }
}

app.get('/api/weather', (req, res) => {
  getFromOpenWeather('weather', req, res);
});

app.get('/api/forecast', (req, res) => {
  getFromOpenWeather('forecast', req, res);
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});