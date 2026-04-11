---
layout: single
title: Local Farms
categories: []
tags: []
status: publish
type: page
published: true
meta: {}
permalink: /farms/
---

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<link rel="stylesheet" href="https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.css" />
<link rel="stylesheet" href="https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.Default.css" />
<link rel="stylesheet" href="/assets/css/farms-map.css" />

<div id="farms-search">
  <input type="text" id="zip-input" placeholder="Enter zip code" maxlength="5" inputmode="numeric" />
  <button id="zip-search-btn">Find farms within 100 miles</button>
  <button id="zip-clear-btn" style="display:none;">Show all farms</button>
  <span id="zip-status"></span>
</div>

<div id="farms-map"></div>

![Map legend](/assets/images/farms/legend.webp)

<div style="text-align: center">Map provided by <a href="https://myhealthforward.com" target="_blank" rel="noopener noreferrer">myhealthforward.com</a></div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://unpkg.com/leaflet.markercluster@1.5.3/dist/leaflet.markercluster.js"></script>
<script src="/assets/js/farms-map.js"></script>
