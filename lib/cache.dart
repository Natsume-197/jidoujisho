import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:jidoujisho/dictionary.dart';
import 'package:jidoujisho/preferences.dart';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:jidoujisho/globals.dart';
import 'package:jidoujisho/youtube.dart';

fetchTrendingCache() {
  return gTrendingCache.runOnce(() async {
    List<Video> trendingVideos = await searchYouTubeTrendingVideos();
    await fetchTrendingChannelCache(trendingVideos);
    return trendingVideos;
  });
}

fetchChannelCache() {
  return gChannelCache.runOnce(() async {
    List<Channel> channels;
    try {
      if (getChannelCache().isNotEmpty) {
        return getChannelCache();
      }
      List<String> channelIDs = getChannelList();
      String channelsMessage = jsonEncode(channelIDs);
      channels = await compute(getSubscribedChannels, channelsMessage);
      if (channels != null && channels.isNotEmpty) {
        setTrendingChannelCache(channels);
      }
    } catch (e) {
      print(e);
    }
    return channels;
  });
}

fetchTrendingChannelCache(List<Video> trendingVideos) {
  return gTrendingChannelCache.runOnce(() async {
    List<Channel> trendingChannels;
    try {
      if (getTrendingChannelCache().isNotEmpty) {
        return getTrendingChannelCache();
      }
      trendingChannels = await compute(getTrendingChannels, trendingVideos);
      if (trendingChannels != null && trendingChannels.isNotEmpty) {
        setTrendingChannelCache(trendingChannels);
      }
    } catch (e) {
      print(e);
    }
    return trendingChannels;
  });
}

fetchChannelVideoCache(String channelID) {
  if (gChannelVideoCache[channelID] == null) {
    gChannelVideoCache[channelID] = [];
  }
  return gChannelVideoCache[channelID];
}

fetchSearchCache(String searchQuery) {
  if (gSearchCache[searchQuery] == null) {
    gSearchCache[searchQuery] = AsyncMemoizer();
  }
  return gSearchCache[searchQuery].runOnce(() async {
    return searchYouTubeVideos(searchQuery);
  });
}

fetchBilingualSearchCache({
  String searchTerm,
  String contextDataSource = "-1",
  int contextPosition = -1,
}) {
  if (gBilingualSearchCache[searchTerm] == null) {
    gBilingualSearchCache[searchTerm] = AsyncMemoizer();
  }

  gBilingualSearchCache[searchTerm].runOnce(() async {
    return getWordDetails(
      searchTerm: searchTerm,
      contextDataSource: contextDataSource,
      contextPosition: contextPosition,
    );
  });

  return gBilingualSearchCache[searchTerm].future;
}

fetchMonolingualSearchCache({
  String searchTerm,
  bool recursive,
  String contextDataSource = "-1",
  int contextPosition = -1,
}) {
  if (gMonolingualSearchCache[searchTerm] == null) {
    gMonolingualSearchCache[searchTerm] = AsyncMemoizer();
  }

  gMonolingualSearchCache[searchTerm].runOnce(() async {
    return getMonolingualWordDetails(
      searchTerm: searchTerm,
      recursive: recursive,
      contextDataSource: contextDataSource,
      contextPosition: contextPosition,
    );
  });

  return gMonolingualSearchCache[searchTerm].future;
}

fetchCustomDictionarySearchCache({
  String dictionaryName,
  String searchTerm,
  String contextDataSource = "-1",
  int contextPosition = -1,
}) {
  if (gCustomDictionarySearchCache[dictionaryName] == null) {
    gCustomDictionarySearchCache[dictionaryName] = {};
  }

  if (gCustomDictionarySearchCache[dictionaryName][searchTerm] == null) {
    gCustomDictionarySearchCache[dictionaryName][searchTerm] = AsyncMemoizer();
  }

  gCustomDictionarySearchCache[dictionaryName][searchTerm].runOnce(() async {
    // TO DO METHOD HERE
    return getCustomWordDetails(
      searchTerm: searchTerm,
      contextDataSource: contextDataSource,
      contextPosition: contextPosition,
    );
  });

  return gCustomDictionarySearchCache[dictionaryName][searchTerm].future;
}

fetchCaptioningCache(String videoID) {
  if (gCaptioningCache[videoID] == null) {
    gCaptioningCache[videoID] = AsyncMemoizer();
  }
  return gCaptioningCache[videoID].runOnce(() async {
    return checkYouTubeClosedCaptionAvailable(videoID);
  });
}

fetchMetadataCache(String videoID, Video video) {
  if (gMetadataCache[videoID] == null) {
    gMetadataCache[videoID] = AsyncMemoizer();
  }
  return gMetadataCache[videoID].runOnce(() async {
    return getPublishMetadata(video);
  });
}
