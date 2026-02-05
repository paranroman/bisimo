import 'package:flutter/material.dart';
import '../data/models/student_model.dart';
import '../data/repositories/student_repository.dart';

/// Provider for managing student data and state
class StudentProvider extends ChangeNotifier {
  final StudentRepository _repository = StudentRepository();

  List<StudentModel> _students = [];
  bool _isLoading = false;
  String? _errorMessage;
  CreateStudentResult? _lastCreateResult;

  // Getters
  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CreateStudentResult? get lastCreateResult => _lastCreateResult;
  int get studentCount => _students.length;

  /// Load students for current Wali Kelas
  Future<void> loadStudents() async {
    _setLoading(true);
    _clearError();

    try {
      _students = await _repository.getStudentsByWaliKelas();
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat daftar murid.');
    } finally {
      _setLoading(false);
    }
  }

  /// Create new student account
  Future<CreateStudentResult> createStudent(CreateStudentData data) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.createStudentAccount(data);
      _lastCreateResult = result;

      if (result.isSuccess) {
        // Add to local list
        if (result.student != null) {
          _students.insert(0, result.student!);
        }
      } else {
        _setError(result.message ?? 'Gagal menambah murid.');
      }

      notifyListeners();
      return result;
    } catch (e) {
      final result = CreateStudentResult.failure(
        message: 'Terjadi kesalahan. Silakan coba lagi.',
      );
      _lastCreateResult = result;
      _setError(result.message!);
      notifyListeners();
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete student
  Future<bool> deleteStudent(String studentId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _repository.deleteStudent(studentId);
      if (success) {
        _students.removeWhere((s) => s.id == studentId);
        notifyListeners();
      } else {
        _setError('Gagal menghapus murid.');
      }
      return success;
    } catch (e) {
      _setError('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Regenerate token for student
  Future<CreateStudentResult> regenerateToken(String studentId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.regenerateToken(studentId);
      _lastCreateResult = result;

      if (!result.isSuccess) {
        _setError(result.message ?? 'Gagal memperbarui token.');
      }

      notifyListeners();
      return result;
    } catch (e) {
      final result = CreateStudentResult.failure(
        message: 'Terjadi kesalahan. Silakan coba lagi.',
      );
      _lastCreateResult = result;
      _setError(result.message!);
      notifyListeners();
      return result;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear last create result
  void clearLastResult() {
    _lastCreateResult = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
