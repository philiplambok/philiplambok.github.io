---
layout: default
title: Music
permalink: /music/
---

<div class="musics">
  {% assign ordered_musics = site.musics | sort:"index" | reverse %}
  {% for music in ordered_musics %}
    <div class="music">
      <a href="{{ music.link }}" target="_blank">
        <img src="{{ music.image_link }}">
      </a>
      <span class="music-title">{{ music.title }}</span>
      <span class="music-artist">by {{ music.artist }}</span>
    </div>
  {% endfor %}
</div>