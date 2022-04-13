
import '...service/core/youtube_api.dart';
import '...service/core/youtube_video.dart';

class YoutubeService {

  static final String key = "AIzaSyBP38EU0CA45rd2umTRjwOwSQ0qUh-edfr"; // ** OWN YOUTUBE V3 API **
  static final YoutubeAPI ytApi = YoutubeAPI(key, maxResults: 5, type: "playlist");
  static final String query = "PLxHGsGbuTY2A2Aauwi84wpQi8eL1DBB6a";//playlist id

  static searchResultsYoutube() async {
    // List<YouTubeVideo> videoResult = await ytApi.search(query); <- REPLACED WITH NEXT
    List<YouTubeVideoPlayList> videoResult = await ytApi.playList(query);
    return videoResult;
  }
}