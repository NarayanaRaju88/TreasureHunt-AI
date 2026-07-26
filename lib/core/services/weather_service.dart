import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';

/// Lightweight weather snapshot used to contextualize AI treasure generation
/// and the home screen greeting.
class WeatherModel extends Equatable {
  const WeatherModel({
    required this.condition,
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    this.cityName,
  });

  /// Short condition, e.g. "Clear", "Clouds", "Rain".
  final String condition;

  /// Detailed description, e.g. "light rain".
  final String description;

  /// Temperature in Celsius.
  final double temperature;

  /// "Feels like" temperature in Celsius.
  final double feelsLike;

  /// OpenWeatherMap icon code, e.g. "10d".
  final String icon;

  /// Relative humidity percentage.
  final int humidity;

  /// Wind speed in meters/second.
  final double windSpeed;

  final String? cityName;

  /// Full icon URL served by OpenWeatherMap.
  String get iconUrl => 'https://play-lh.googleusercontent.com/ooGrukpBdHiCt231zCvHQ2uOtnKvhsGqxsz-qiYpY36uDP0ib2Y1EAzdRRYJoHkceBiWdx4PVIF0kJZ6SZaPMQ';

  factory WeatherModel.fromOpenWeather(Map<String, dynamic> json) {
    final weatherList = json['weather'] as List?;
    final weather0 = (weatherList != null && weatherList.isNotEmpty)
        ? Map<String, dynamic>.from(weatherList.first as Map)
        : const <String, dynamic>{};
    final main = json['main'] is Map
        ? Map<String, dynamic>.from(json['main'] as Map)
        : const <String, dynamic>{};
    final wind = json['wind'] is Map
        ? Map<String, dynamic>.from(json['wind'] as Map)
        : const <String, dynamic>{};

    return WeatherModel(
      condition: (weather0['main'] ?? 'Unknown').toString(),
      description: (weather0['description'] ?? '').toString(),
      temperature: _asDouble(main['temp']),
      feelsLike: _asDouble(main['feels_like']),
      icon: (weather0['icon'] ?? '01d').toString(),
      humidity: _asInt(main['humidity']),
      windSpeed: _asDouble(wind['speed']),
      cityName: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'condition': condition,
        'description': description,
        'temperature': temperature,
        'feelsLike': feelsLike,
        'icon': icon,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'cityName': cityName,
      };

  /// A compact human summary, e.g. "Clear, 27°C".
  String get summary => '$condition, ${temperature.round()}°C';

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => <Object?>[
        condition,
        description,
        temperature,
        feelsLike,
        icon,
        humidity,
        windSpeed,
        cityName,
      ];
}

/// Fetches current weather from the OpenWeatherMap free "Current Weather" API.
class WeatherService {
  WeatherService({Dio? dio, String? apiKey})
      : _apiKey = apiKey ?? AppConstants.weatherApiKey,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.openweathermap.org/data/2.5',
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
              ),
            );

  final Dio _dio;
  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Gets the current weather for the given coordinates.
  ///
  /// [units] is `metric` (Celsius) by default.
  Future<WeatherModel> getCurrentWeather(
    double lat,
    double lng, {
    String units = 'metric',
  }) async {
    if (!isConfigured) {
      throw const AIServiceException(
        'Weather is not configured. Missing weather API key.',
        code: 'not-configured',
      );
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/weather',
        queryParameters: <String, dynamic>{
          'lat': lat,
          'lon': lng,
          'units': units,
          'appid': _apiKey,
        },
      );
      final data = response.data;
      if (data == null) throw const ServerException('Empty weather response.');
      return WeatherModel.fromOpenWeather(data);
    } on DioException catch (e, st) {
      throw _mapDio(e, st);
    } catch (e, st) {
      throw UnknownException('Failed to load weather.', e, st);
    }
  }

  /// Gets the current weather for a named city.
  Future<WeatherModel> getWeatherByCity(
    String city, {
    String units = 'metric',
  }) async {
    if (!isConfigured) {
      throw const AIServiceException(
        'Weather is not configured. Missing weather API key.',
        code: 'not-configured',
      );
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/weather',
        queryParameters: <String, dynamic>{
          'q': city,
          'units': units,
          'appid': _apiKey,
        },
      );
      final data = response.data;
      if (data == null) throw const ServerException('Empty weather response.');
      return WeatherModel.fromOpenWeather(data);
    } on DioException catch (e, st) {
      throw _mapDio(e, st);
    } catch (e, st) {
      throw UnknownException('Failed to load weather.', e, st);
    }
  }

  AppException _mapDio(DioException e, StackTrace st) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout();
      case DioExceptionType.connectionError:
        return NetworkException.offline();
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401) {
          return const ServerException(
            'Weather API key is invalid.',
            statusCode: 401,
            code: 'invalid-api-key',
          );
        }
        return ServerException(
          'Weather service error. Please try again.',
          statusCode: status,
          code: 'bad-response',
          cause: e,
          stackTrace: st,
        );
      default:
        return NetworkException(
          'Could not reach the weather service.',
          code: 'network',
          cause: e,
          stackTrace: st,
        );
    }
  }
}
