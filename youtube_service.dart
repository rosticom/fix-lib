
import 'package:topointme/view/widget/video_content/youtube/service/core/youtube_api.dart';
import 'package:topointme/view/widget/video_content/youtube/youtube_video.dart';

class YoutubeService {

  static final String key = "AIzaSyA2ornWK5NgPEcIL_poBgymseTdxQr4VOg"; // ** OWN API **
  static final YoutubeAPI ytApi = YoutubeAPI(key, maxResults: 5, type: "playlist");//playlist
  static final String query = "PLxHGsGbuTY2A2Aauwi84wpQi8eL1DBB6a";//playlist

  static searchResultsYoutube() async {
    // List<YouTubeVideo> _videoResult = await ytApi.search(query);
    List<YouTubeVideoPlayList> _videoResult = await ytApi.playList(query);
    return _videoResult;
  }
}