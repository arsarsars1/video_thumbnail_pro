package com.ars.video_thumbnail_pro;

import static org.junit.Assert.assertNotNull;

import org.junit.Test;

public class VideoThumbnailProPluginTest {
  @Test
  public void instantiatePlugin_succeeds() {
    VideoThumbnailProPlugin plugin = new VideoThumbnailProPlugin();
    assertNotNull(plugin);
  }
}
