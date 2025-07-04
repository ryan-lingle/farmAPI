# Property Management with Google Maps Integration

This guide explains how to implement property management features in your Next.js frontend application using the farmAPI backend with Google Maps integration.

## Overview

The property management system allows users to:
1. Search for properties by address using Google Maps Geocoding
2. View properties on an interactive map
3. Draw and edit property boundaries
4. Save properties with custom boundaries
5. Link properties to farm assets

## Prerequisites

1. Google Maps API Key with the following APIs enabled:
   - Geocoding API
   - Maps JavaScript API
   - Places API

2. Set the API key in your farmAPI backend:
   ```bash
   export GOOGLE_MAPS_API_KEY=your_api_key_here
   ```

## API Endpoints

### Geocoding Endpoints

```
GET  /api/v1/geocoding/geocode?address={address}
GET  /api/v1/geocoding/reverse?latitude={lat}&longitude={lng}
GET  /api/v1/geocoding/search_nearby?latitude={lat}&longitude={lng}&radius={radius}
GET  /api/v1/geocoding/place/{place_id}
```

### Property Management Endpoints

```
GET    /api/v1/properties
GET    /api/v1/properties/{id}
POST   /api/v1/properties/create_from_address
PATCH  /api/v1/properties/{id}/boundaries
GET    /api/v1/properties/search/nearby?latitude={lat}&longitude={lng}&radius={radius}
POST   /api/v1/properties/{id}/link_asset
```

## Frontend Implementation Guide

### 1. Install Required Dependencies

```bash
npm install @react-google-maps/api
npm install axios # or your preferred HTTP client
```

### 2. Create Google Maps Provider Component

```jsx
// components/GoogleMapsProvider.jsx
import { LoadScript } from '@react-google-maps/api';

const libraries = ['places', 'drawing', 'geometry'];

export default function GoogleMapsProvider({ children }) {
  return (
    <LoadScript
      googleMapsApiKey={process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY}
      libraries={libraries}
    >
      {children}
    </LoadScript>
  );
}
```

### 3. Create Property Map Component

```jsx
// components/PropertyMap.jsx
import { GoogleMap, Polygon, DrawingManager } from '@react-google-maps/api';
import { useState, useCallback } from 'react';

const mapContainerStyle = {
  width: '100%',
  height: '600px'
};

const defaultCenter = {
  lat: 39.8283, // Default to Indiana
  lng: -86.1581
};

const drawingOptions = {
  drawingControl: true,
  drawingControlOptions: {
    drawingModes: ['polygon']
  },
  polygonOptions: {
    fillColor: '#2196F3',
    fillOpacity: 0.3,
    strokeWeight: 2,
    strokeColor: '#1976D2',
    editable: true,
    draggable: true
  }
};

export default function PropertyMap({ onBoundariesChange, initialBoundaries }) {
  const [map, setMap] = useState(null);
  const [polygon, setPolygon] = useState(null);

  const onLoad = useCallback((map) => {
    setMap(map);
  }, []);

  const onPolygonComplete = useCallback((polygon) => {
    // Get the coordinates
    const paths = polygon.getPath();
    const coordinates = [];
    
    paths.forEach((latLng) => {
      coordinates.push({
        latitude: latLng.lat(),
        longitude: latLng.lng()
      });
    });

    // Remove the drawing manager polygon and create an editable one
    polygon.setMap(null);
    setPolygon(polygon);
    
    if (onBoundariesChange) {
      onBoundariesChange(coordinates);
    }
  }, [onBoundariesChange]);

  const convertToGooglePaths = (boundaries) => {
    return boundaries.map(point => ({
      lat: point.latitude,
      lng: point.longitude
    }));
  };

  return (
    <GoogleMap
      mapContainerStyle={mapContainerStyle}
      center={defaultCenter}
      zoom={12}
      onLoad={onLoad}
    >
      {initialBoundaries && (
        <Polygon
          paths={convertToGooglePaths(initialBoundaries)}
          options={drawingOptions.polygonOptions}
          editable={true}
          onMouseUp={(e) => {
            // Handle boundary updates
            const paths = e.getPath();
            const coordinates = [];
            paths.forEach((latLng) => {
              coordinates.push({
                latitude: latLng.lat(),
                longitude: latLng.lng()
              });
            });
            onBoundariesChange(coordinates);
          }}
        />
      )}
      
      <DrawingManager
        options={drawingOptions}
        onPolygonComplete={onPolygonComplete}
      />
    </GoogleMap>
  );
}
```

### 4. Create Property Search Component

```jsx
// components/PropertySearch.jsx
import { useState } from 'react';
import axios from 'axios';

export default function PropertySearch({ onPropertyFound }) {
  const [address, setAddress] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const searchAddress = async () => {
    setLoading(true);
    setError(null);
    
    try {
      // First geocode the address
      const geocodeResponse = await axios.get(
        `/api/v1/geocoding/geocode?address=${encodeURIComponent(address)}`
      );
      
      if (geocodeResponse.data.data) {
        const geocodeData = geocodeResponse.data.data.attributes;
        
        // Create a property from the address
        const propertyResponse = await axios.post(
          '/api/v1/properties/create_from_address',
          {
            address: address,
            property_type: 'farm',
            location_type: 'polygon'
          }
        );
        
        if (propertyResponse.data.data) {
          onPropertyFound(propertyResponse.data.data);
        }
      }
    } catch (err) {
      setError(err.response?.data?.errors?.[0]?.detail || 'Search failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="property-search">
      <div className="search-input-group">
        <input
          type="text"
          value={address}
          onChange={(e) => setAddress(e.target.value)}
          placeholder="Enter property address..."
          className="search-input"
          onKeyPress={(e) => e.key === 'Enter' && searchAddress()}
        />
        <button 
          onClick={searchAddress} 
          disabled={loading || !address}
          className="search-button"
        >
          {loading ? 'Searching...' : 'Search'}
        </button>
      </div>
      {error && <div className="error-message">{error}</div>}
    </div>
  );
}
```

### 5. Create Main Property Management Page

```jsx
// pages/properties/manage.jsx
import { useState } from 'react';
import GoogleMapsProvider from '../../components/GoogleMapsProvider';
import PropertyMap from '../../components/PropertyMap';
import PropertySearch from '../../components/PropertySearch';
import axios from 'axios';

export default function PropertyManagement() {
  const [selectedProperty, setSelectedProperty] = useState(null);
  const [boundaries, setBoundaries] = useState(null);
  const [saving, setSaving] = useState(false);

  const handlePropertyFound = (property) => {
    setSelectedProperty(property);
    setBoundaries(property.attributes.geometry);
    
    // Center map on property
    if (property.attributes.center_point) {
      // You can pass this to the map component to center it
    }
  };

  const handleBoundariesChange = (newBoundaries) => {
    setBoundaries(newBoundaries);
  };

  const saveBoundaries = async () => {
    if (!selectedProperty || !boundaries) return;
    
    setSaving(true);
    try {
      const response = await axios.patch(
        `/api/v1/properties/${selectedProperty.id}/boundaries`,
        { geometry: boundaries }
      );
      
      if (response.data.data) {
        alert('Property boundaries saved successfully!');
        setSelectedProperty(response.data.data);
      }
    } catch (err) {
      alert('Failed to save boundaries');
    } finally {
      setSaving(false);
    }
  };

  return (
    <GoogleMapsProvider>
      <div className="property-management">
        <h1>Property Management</h1>
        
        <div className="search-section">
          <h2>Find Property</h2>
          <PropertySearch onPropertyFound={handlePropertyFound} />
        </div>

        {selectedProperty && (
          <div className="property-details">
            <h2>Property: {selectedProperty.attributes.name}</h2>
            <p>Type: {selectedProperty.attributes.location_type}</p>
            {selectedProperty.attributes.area_in_acres && (
              <p>Area: {selectedProperty.attributes.area_in_acres} acres</p>
            )}
          </div>
        )}

        <div className="map-section">
          <h2>Property Boundaries</h2>
          <PropertyMap
            onBoundariesChange={handleBoundariesChange}
            initialBoundaries={boundaries}
          />
          
          {selectedProperty && (
            <button
              onClick={saveBoundaries}
              disabled={saving}
              className="save-button"
            >
              {saving ? 'Saving...' : 'Save Boundaries'}
            </button>
          )}
        </div>

        <div className="instructions">
          <h3>Instructions:</h3>
          <ol>
            <li>Search for a property by entering its address</li>
            <li>The map will show an initial boundary based on the property's viewport</li>
            <li>Click the polygon tool in the map controls to draw custom boundaries</li>
            <li>Click on the map to add points to your boundary</li>
            <li>Complete the polygon by clicking on the first point</li>
            <li>You can edit the boundary by dragging the points</li>
            <li>Click "Save Boundaries" when done</li>
          </ol>
        </div>
      </div>
    </GoogleMapsProvider>
  );
}
```

### 6. Styling (Optional)

```css
/* styles/properties.css */
.property-management {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.search-section {
  margin-bottom: 30px;
}

.search-input-group {
  display: flex;
  gap: 10px;
  max-width: 500px;
}

.search-input {
  flex: 1;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
}

.search-button, .save-button {
  padding: 10px 20px;
  background-color: #2196F3;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
}

.search-button:hover, .save-button:hover {
  background-color: #1976D2;
}

.search-button:disabled, .save-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.error-message {
  color: #d32f2f;
  margin-top: 10px;
}

.property-details {
  background-color: #f5f5f5;
  padding: 15px;
  border-radius: 4px;
  margin-bottom: 20px;
}

.map-section {
  margin-bottom: 30px;
}

.instructions {
  background-color: #e3f2fd;
  padding: 15px;
  border-radius: 4px;
}

.instructions h3 {
  margin-top: 0;
}

.instructions ol {
  margin-bottom: 0;
}
```

## Advanced Features

### 1. Listing All Properties

```jsx
// components/PropertyList.jsx
import { useState, useEffect } from 'react';
import axios from 'axios';

export default function PropertyList({ onSelectProperty }) {
  const [properties, setProperties] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProperties();
  }, []);

  const fetchProperties = async () => {
    try {
      const response = await axios.get('/api/v1/properties?only_properties=true');
      setProperties(response.data.data || []);
    } catch (err) {
      console.error('Failed to fetch properties:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading properties...</div>;

  return (
    <div className="property-list">
      <h3>Saved Properties</h3>
      {properties.length === 0 ? (
        <p>No properties found</p>
      ) : (
        <ul>
          {properties.map(property => (
            <li key={property.id}>
              <button onClick={() => onSelectProperty(property)}>
                {property.attributes.name}
              </button>
              {property.attributes.area_in_acres && (
                <span> ({property.attributes.area_in_acres} acres)</span>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

### 2. Linking Properties to Assets

```jsx
// components/LinkPropertyToAsset.jsx
import { useState } from 'react';
import axios from 'axios';

export default function LinkPropertyToAsset({ propertyId }) {
  const [assetId, setAssetId] = useState('');
  const [linking, setLinking] = useState(false);

  const linkAsset = async () => {
    setLinking(true);
    try {
      const response = await axios.post(
        `/api/v1/properties/${propertyId}/link_asset`,
        {
          asset_id: assetId,
          asset_type: 'land'
        }
      );
      
      if (response.data.data) {
        alert('Property linked to asset successfully!');
        setAssetId('');
      }
    } catch (err) {
      alert('Failed to link property to asset');
    } finally {
      setLinking(false);
    }
  };

  return (
    <div className="link-asset">
      <h3>Link to Land Asset</h3>
      <input
        type="text"
        value={assetId}
        onChange={(e) => setAssetId(e.target.value)}
        placeholder="Enter Land Asset ID"
      />
      <button 
        onClick={linkAsset} 
        disabled={linking || !assetId}
      >
        {linking ? 'Linking...' : 'Link Asset'}
      </button>
    </div>
  );
}
```

## Environment Variables

Add these to your Next.js `.env.local` file:

```
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=your_google_maps_api_key
NEXT_PUBLIC_API_URL=http://localhost:3000
```

## API Configuration

Create an API client for consistent configuration:

```jsx
// lib/api.js
import axios from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',
  headers: {
    'Content-Type': 'application/json',
  },
});

export default api;
```

## Error Handling

Always handle API errors gracefully:

```jsx
try {
  const response = await api.get('/api/v1/properties');
  // Handle success
} catch (error) {
  if (error.response) {
    // Server responded with error
    console.error('Error:', error.response.data);
  } else if (error.request) {
    // Request made but no response
    console.error('Network error:', error.request);
  } else {
    // Something else happened
    console.error('Error:', error.message);
  }
}
```

## Testing

Test the integration with these steps:

1. Start your farmAPI backend with the Google Maps API key set
2. Start your Next.js frontend
3. Navigate to the property management page
4. Search for an address (e.g., "1600 Amphitheatre Parkway, Mountain View, CA")
5. Draw custom boundaries on the map
6. Save the property

## Troubleshooting

### Common Issues:

1. **Google Maps not loading**: Check that your API key is set correctly and has the required APIs enabled
2. **Geocoding fails**: Ensure the Geocoding API is enabled in Google Cloud Console
3. **Drawing tools not showing**: Make sure the `drawing` library is included in LoadScript
4. **CORS errors**: Ensure your farmAPI is configured to accept requests from your frontend domain

### Debug Tips:

- Check browser console for JavaScript errors
- Use Network tab to inspect API requests/responses
- Verify API keys are properly set in both frontend and backend
- Test API endpoints directly with curl or Postman

## Next Steps

1. Add property image uploads
2. Implement property sharing between users
3. Add weather data overlay for properties
4. Integrate with crop planning features
5. Add soil type mapping
6. Implement property history tracking

## Support

For issues or questions:
1. Check the farmAPI logs for backend errors
2. Review Google Maps API documentation
3. Ensure all required Google APIs are enabled
4. Check API quota limits in Google Cloud Console 