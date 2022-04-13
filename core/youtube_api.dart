
import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:topointme/view/widget/video_content/youtube/service/core/playlist_api.dart';
import 'package:topointme/view/widget/video_content/youtube/youtube_video.dart';
import 'package:youtube_api/src/model/video.dart';
import 'package:youtube_api/src/util/get_duration.dart';

class YoutubeAPI {
  String? type;
  String? query;
  String? prevPageToken;
  String? nextPageToken;
  int maxResults;
  ApiHelper? api;
  int page = 0;
  String? regionCode;
  bool? getTrending;
  final headers = {"Accept": "application/json"};
  static String baseURL = 'www.googleapis.com';
  YoutubeAPI(
    String key, {
    this.type,
    this.maxResults = 10,
  }) {
    this.type = type;
    this.maxResults = maxResults;
    api = ApiHelper(key: key, maxResults: this.maxResults, type: this.type);
  }

  Future<List<YouTubeVideoPlayList>> getTrends({
    required String regionCode,
  }) async {
    this.regionCode = regionCode;
    this.getTrending = true;
    final url = api!.trendingUri(regionCode: regionCode);
    final res = await http.get(url, headers: headers);
    final jsonData = json.decode(res.body);
    if (jsonData['error'] != null) {
      throw jsonData['error']['message'];
    }
    if (jsonData['pageInfo']['totalResults'] == null) return <YouTubeVideoPlayList>[];
    final result = await _getResultFromJson(jsonData);
    return result;
  }

   Future<List<YouTubeVideoPlayList>> playList(String query, {String? type}) async {
    this.query = query;
    Uri url = api!.playlistItems(query, type);
    var res = await http.get(url, headers: {"Accept": "application/json"});
    // print ('playlist url:');
    print (url);
    var jsonData = json.decode(res.body);
    if (jsonData['error'] != null) {
      throw jsonData['error']['message'];
    }
    if (jsonData['pageInfo']['totalResults'] == null) return <YouTubeVideoPlayList>[];
    List<YouTubeVideoPlayList> result = await _getResultFromJson(jsonData);
    return result;
  }

  Future<List<YouTubeVideoPlayList>> search(
    String query, {
    String type = 'video,channel,playlist',
    String order = 'relevance',
    String videoDuration = 'any',
    String? regionCode,
  }) async {
    this.getTrending = false;
    this.query = query;
    final url = api!.searchUri(
      query,
      type: type,
      videoDuration: videoDuration,
      order: order,
      regionCode: regionCode,
    );
    // print("url:");
    // print(url);
    var res = await http.get(url, headers: headers);
    var jsonData = json.decode(res.body);
    if (jsonData['error'] != null) {
      throw jsonData['error']['message'];
    }
    if (jsonData['pageInfo']['totalResults'] == null) return <YouTubeVideoPlayList>[];
    List<YouTubeVideoPlayList> result = await _getResultFromJson(jsonData);
    return result;
  }

  Future<List<YouTubeVideoPlayList>> channel(String channelId, {String? order}) async {
    this.getTrending = false;
    final url = api!.channelUri(channelId, order);
    var res = await http.get(url, headers: headers);
    var jsonData = json.decode(res.body);
    if (jsonData['error'] != null) {
      throw jsonData['error']['message'];
    }
    if (jsonData['pageInfo']['totalResults'] == null) return <YouTubeVideoPlayList>[];
    List<YouTubeVideoPlayList> result = await _getResultFromJson(jsonData);
    return result;
  }

  /*
  Get video details from video Id
   */
  Future<List<Video>> video(List<String> videoId) async {
    List<Video> result = [];
    final url = api!.videoUri(videoId);
    var res = await http.get(url, headers: headers);
    var jsonData = json.decode(res.body);

    if (jsonData == null) return [];

    int total = jsonData['pageInfo']['totalResults'] <
            jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];

    for (int i = 0; i < total; i++) {
      result.add(new Video(jsonData['items'][i]));
    }
    return result;
  }

  Future<List<YouTubeVideoPlayList>> _getResultFromJson(jsonData) async {
    List<YouTubeVideoPlayList>? result = [];
    if (jsonData == null) return [];
    nextPageToken = jsonData['nextPageToken'];
    api!.setNextPageToken(nextPageToken!);
    int total = jsonData['pageInfo']['totalResults'] <
            jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];
    result = await _getListOfYTAPIs(jsonData, total);
    page = 1;
    return result ?? [];
  }

  Future<List<YouTubeVideoPlayList>?> _getListOfYTAPIs(dynamic data, int total) async {
    List<YouTubeVideoPlayList> result = [];
    List<String> videoIdList = [];
    for (int i = 0; i < total; i++) {
      YouTubeVideoPlayList ytApiObj =
          // YouTubeVideo(data['items'][i], getTrendingVideo: getTrending);
          YouTubeVideoPlayList(data['items'][i], getTrendingVideo: false);
      if (ytApiObj.kind == "video") videoIdList.add(ytApiObj.id!);
      result.add(ytApiObj);
    }
    List<Video> videoList = await video(videoIdList);
    await Future.forEach(videoList, (Video ytVideo) {
      YouTubeVideoPlayList? ytAPIObj =
          result.firstWhereOrNull((ytAPI) => ytAPI.id == ytVideo.id);
      ytAPIObj?.duration = getDuration(ytVideo.duration ?? "") ?? "";
    });
    return result;
  }

  Future<List<YouTubeVideoPlayList>> nextPage() async {
    this.getTrending = false;
    if (api!.nextPageToken == null) return [];
    List<YouTubeVideoPlayList>? result = [];
    final url = api!.nextPageUri(this.getTrending!);
    var res = await http.get(url, headers: headers);
    var jsonData = json.decode(res.body);

    if (jsonData['pageInfo']['totalResults'] == null) return <YouTubeVideoPlayList>[];

    if (jsonData == null) return <YouTubeVideoPlayList>[];

    nextPageToken = jsonData['nextPageToken'];
    prevPageToken = jsonData['prevPageToken'];
    api!.setNextPageToken(nextPageToken!);
    api!.setPrevPageToken(prevPageToken!);
    int total = jsonData['pageInfo']['totalResults'] <
            jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];
    result = await _getListOfYTAPIs(jsonData, total);
    page++;
    if (total == 0) {
      return <YouTubeVideoPlayList>[];
    }
    return result ?? [];
  }

  Future<List<YouTubeVideoPlayList>?> prevPage() async {
    if (api!.prevPageToken == null) return null;
    List<YouTubeVideoPlayList>? result = [];
    final url = api!.prevPageUri(this.getTrending!);
    var res = await http.get(url, headers: headers);
    var jsonData = json.decode(res.body);

    if (jsonData['pageInfo']['totalResults'] == null) return <YouTubeVideoPlayList>[];

    if (jsonData == null) return <YouTubeVideoPlayList>[];

    nextPageToken = jsonData['nextPageToken'];
    prevPageToken = jsonData['prevPageToken'];
    api!.setNextPageToken(nextPageToken!);
    api!.setPrevPageToken(prevPageToken!);
    int total = jsonData['pageInfo']['totalResults'] <
            jsonData['pageInfo']['resultsPerPage']
        ? jsonData['pageInfo']['totalResults']
        : jsonData['pageInfo']['resultsPerPage'];
    result = (await _getListOfYTAPIs(jsonData, total) ?? []).cast<YouTubeVideoPlayList>();
    if (total == 0) {
      return <YouTubeVideoPlayList>[];
    }
    page--;
    return result;
  }

  int get getPage => page;

  set setMaxResults(int maxResults) => this.maxResults = maxResults;

  get getMaxResults => this.maxResults;

  set setKey(String key) => api!.key = key;

  set setQuery(String query) => api!.query = query;

  String? get getQuery => api!.query;

  set setType(String type) => api!.type = type;

  String? get getType => api!.type;
}
