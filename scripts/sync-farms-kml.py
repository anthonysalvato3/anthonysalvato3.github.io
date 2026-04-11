#!/usr/bin/env python3
"""Download KML from Google My Maps and convert to GeoJSON."""

import json
import os
import re
import urllib.request
from xml.etree import ElementTree as ET

KML_URL = "https://www.google.com/maps/d/kml?forcekml=1&mid=1sEtufBsicCwZVucez3fAHTdsGumzAy4"
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "data", "farms.geojson")

NS = {"kml": "http://www.opengis.net/kml/2.2"}


def kml_color_to_hex(kml_color):
    """Convert KML AABBGGRR color to #RRGGBB."""
    if not kml_color or len(kml_color) < 8:
        return "#FF0000"
    # KML format: AABBGGRR
    kml_color = kml_color.strip().lstrip("#")
    r = kml_color[6:8]
    g = kml_color[4:6]
    b = kml_color[2:4]
    return f"#{r}{g}{b}".upper()


def extract_styles(root):
    """Build a mapping from style ID to hex color."""
    styles = {}

    # Collect all <Style> elements with an id
    for style in root.iter(f"{{{NS['kml']}}}Style"):
        style_id = style.get("id")
        if not style_id:
            continue
        icon_style = style.find(".//kml:IconStyle/kml:color", NS)
        if icon_style is not None and icon_style.text:
            styles[style_id] = kml_color_to_hex(icon_style.text)

    # Resolve <StyleMap> elements to their normal style
    for style_map in root.iter(f"{{{NS['kml']}}}StyleMap"):
        map_id = style_map.get("id")
        if not map_id:
            continue
        for pair in style_map.findall("kml:Pair", NS):
            key = pair.find("kml:key", NS)
            if key is not None and key.text == "normal":
                style_url = pair.find("kml:styleUrl", NS)
                if style_url is not None:
                    ref = style_url.text.lstrip("#")
                    if ref in styles:
                        styles[map_id] = styles[ref]

    return styles


def resolve_color(style_url, styles):
    """Resolve a styleUrl reference to a hex color."""
    if not style_url:
        return "#FF0000"
    ref = style_url.lstrip("#")
    return styles.get(ref, "#FF0000")


def extract_placemarks(root, styles):
    """Extract all Placemarks as GeoJSON features."""
    features = []

    for placemark in root.iter(f"{{{NS['kml']}}}Placemark"):
        name_el = placemark.find("kml:name", NS)
        desc_el = placemark.find("kml:description", NS)
        style_url_el = placemark.find("kml:styleUrl", NS)
        coords_el = placemark.find(".//kml:Point/kml:coordinates", NS)

        if coords_el is None or not coords_el.text:
            continue

        # Parse coordinates (lon,lat,elevation)
        parts = coords_el.text.strip().split(",")
        if len(parts) < 2:
            continue
        lon = float(parts[0])
        lat = float(parts[1])

        name = name_el.text.strip() if name_el is not None and name_el.text else ""
        description = desc_el.text.strip() if desc_el is not None and desc_el.text else ""
        style_url = style_url_el.text if style_url_el is not None else ""
        color = resolve_color(style_url, styles)

        features.append({
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [lon, lat],
            },
            "properties": {
                "name": name,
                "description": description,
                "color": color,
            },
        })

    return features


def main():
    print(f"Downloading KML from {KML_URL}...")
    req = urllib.request.Request(KML_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as response:
        kml_data = response.read()

    print("Parsing KML...")
    root = ET.fromstring(kml_data)

    styles = extract_styles(root)
    print(f"Found {len(styles)} styles")

    features = extract_placemarks(root, styles)
    print(f"Found {len(features)} farms/locations")

    geojson = {
        "type": "FeatureCollection",
        "features": features,
    }

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(geojson, f, ensure_ascii=False, separators=(",", ":"))

    print(f"Wrote {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
