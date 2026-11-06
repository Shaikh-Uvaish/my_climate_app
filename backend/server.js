const express = require('express');
const mongoose = require('mongoose');

const app = express();
app.use(express.json()); // lets the server read JSON sent in the body

const PORT = 3000;
const API_KEY = 'PASTE_YOUR_API_KEY_HERE';
const BASE_URL = 'https://api.openweathermap.org/data/2.5';

// Local MongoDB. "climate_app" is the database name (created automatically).
const MONGO_URL = 'mongodb://127.0.0.1:27017/climate_app';

// ---------- Database model ----------
const favoriteSchema = new mongoose.Schema({
  name: String,      // shown in the app, e.g. "Mumbai"
  nameLower: String, // used to stop duplicates, e.g. "mumbai"
});

const Favorite = mongoose.model('Favorite', favoriteSchema);

// ---------- Weather routes ----------
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

// ---------- Favorite cities routes ----------

// Get all favorites
app.get('/api/favorites', async (req, res) => {
  try {
    const favorites = await Favorite.find();
    res.json(favorites);
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: 'Something went wrong' });
  }
});

// Add a favorite. Body: { "name": "Mumbai" }
app.post('/api/favorites', async (req, res) => {
  try {
    const name = (req.body.name || '').trim();

    if (!name) {
      return res.status(400).json({ error: 'Please give a city name' });
    }

    const alreadySaved = await Favorite.findOne({ nameLower: name.toLowerCase() });
    if (alreadySaved) {
      return res.status(409).json({ error: `${name} is already in favorites` });
    }

    const favorite = await Favorite.create({
      name: name,
      nameLower: name.toLowerCase(),
    });

    res.status(201).json(favorite);
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: 'Something went wrong' });
  }
});

// Delete a favorite by its id
app.delete('/api/favorites/:id', async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: 'Invalid id' });
    }

    const deleted = await Favorite.findByIdAndDelete(req.params.id);
    if (!deleted) {
      return res.status(404).json({ error: 'Favorite not found' });
    }

    res.json({ message: 'Deleted' });
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: 'Something went wrong' });
  }
});

// ---------- Start: connect to MongoDB first, then start the server ----------
mongoose
  .connect(MONGO_URL)
  .then(() => {
    console.log('Connected to MongoDB');
    app.listen(PORT, () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  })
  .catch((error) => {
    console.log('Could not connect to MongoDB. Is it running?');
    console.log(error.message);
  });