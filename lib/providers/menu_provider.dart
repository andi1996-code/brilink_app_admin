import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class MenuProvider extends ChangeNotifier {
  final ApiService apiService;
  bool isLoading = false;
  List<dynamic> menus = [];
  String? errorMessage;

  MenuProvider({required this.apiService});

  Future<void> loadMenus() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await apiService.get('/menus');
      menus = resp.data as List<dynamic>;
    } on DioException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
