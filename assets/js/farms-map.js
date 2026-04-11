(function () {
  var map = L.map("farms-map", { preferCanvas: true }).setView(
    [39.8283, -98.5795],
    4
  );

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 18,
  }).addTo(map);

  var cluster = L.markerClusterGroup({ maxClusterRadius: 50 });
  map.addLayer(cluster);

  var allMarkers = [];
  var zipData = null;

  // Load GeoJSON and add markers
  fetch("/assets/data/farms.geojson")
    .then(function (res) {
      return res.json();
    })
    .then(function (geojson) {
      geojson.features.forEach(function (feature) {
        var coords = feature.geometry.coordinates;
        var props = feature.properties;
        var marker = L.circleMarker([coords[1], coords[0]], {
          radius: 8,
          fillColor: props.color,
          color: "#fff",
          weight: 2,
          opacity: 1,
          fillOpacity: 0.8,
        });

        var popupContent = "<strong>" + escapeHtml(props.name) + "</strong>";
        if (props.description) {
          popupContent += "<br>" + props.description;
        }
        marker.bindPopup(popupContent);
        marker._farmCoords = [coords[1], coords[0]];
        allMarkers.push(marker);
      });

      cluster.addLayers(allMarkers);
    });

  // Zip code search
  var zipInput = document.getElementById("zip-input");
  var searchBtn = document.getElementById("zip-search-btn");
  var clearBtn = document.getElementById("zip-clear-btn");
  var status = document.getElementById("zip-status");

  searchBtn.addEventListener("click", doSearch);
  zipInput.addEventListener("keydown", function (e) {
    if (e.key === "Enter") doSearch();
  });
  clearBtn.addEventListener("click", resetMap);

  function doSearch() {
    var zip = zipInput.value.trim();
    if (!/^\d{5}$/.test(zip)) {
      status.textContent = "Please enter a valid 5-digit zip code.";
      status.className = "error";
      return;
    }

    status.textContent = "Searching...";
    status.className = "";

    loadZipData().then(function () {
      var loc = zipData.get(zip);
      if (!loc) {
        status.textContent = "Zip code not found.";
        status.className = "error";
        return;
      }

      var nearby = [];
      allMarkers.forEach(function (marker) {
        var dist = haversine(
          loc.lat,
          loc.lon,
          marker._farmCoords[0],
          marker._farmCoords[1]
        );
        if (dist <= 100) {
          nearby.push(marker);
        }
      });

      cluster.clearLayers();
      cluster.addLayers(nearby);

      if (nearby.length === 0) {
        status.textContent = "No farms found within 100 miles of " + zip + ".";
        status.className = "";
        map.setView([loc.lat, loc.lon], 8);
      } else {
        status.textContent =
          nearby.length + " farm" + (nearby.length !== 1 ? "s" : "") +
          " within 100 miles of " + zip + ".";
        status.className = "";
        var group = L.featureGroup(nearby);
        map.fitBounds(group.getBounds().pad(0.1));
      }

      clearBtn.style.display = "inline-block";
    });
  }

  function resetMap() {
    cluster.clearLayers();
    cluster.addLayers(allMarkers);
    map.setView([39.8283, -98.5795], 4);
    clearBtn.style.display = "none";
    status.textContent = "";
    zipInput.value = "";
  }

  function loadZipData() {
    if (zipData) return Promise.resolve();
    return fetch("/assets/data/us-zipcodes.csv")
      .then(function (res) {
        return res.text();
      })
      .then(function (text) {
        zipData = new Map();
        var lines = text.split("\n");
        for (var i = 1; i < lines.length; i++) {
          var parts = lines[i].split(",");
          if (parts.length >= 3) {
            zipData.set(parts[0], {
              lat: parseFloat(parts[1]),
              lon: parseFloat(parts[2]),
            });
          }
        }
      });
  }

  function haversine(lat1, lon1, lat2, lon2) {
    var R = 3958.8; // Earth radius in miles
    var dLat = toRad(lat2 - lat1);
    var dLon = toRad(lon2 - lon1);
    var a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  function toRad(deg) {
    return (deg * Math.PI) / 180;
  }

  function escapeHtml(text) {
    var div = document.createElement("div");
    div.appendChild(document.createTextNode(text));
    return div.innerHTML;
  }
})();
