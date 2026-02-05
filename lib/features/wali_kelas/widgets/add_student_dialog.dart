import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../data/models/student_model.dart';
import '../../../providers/student_provider.dart';

/// Dialog for adding a new student
class AddStudentDialog extends StatefulWidget {
  const AddStudentDialog({super.key});

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _namaPanggilanController = TextEditingController();
  final _kelasController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedEducation;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _educationOptions = ['SD', 'SMP', 'SMA'];

  @override
  void dispose() {
    _namaController.dispose();
    _namaPanggilanController.dispose();
    _kelasController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF41B37E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleSubmit() async {
    // Validate
    if (_namaController.text.trim().isEmpty) {
      _showError('Nama tidak boleh kosong');
      return;
    }
    if (_namaPanggilanController.text.trim().isEmpty) {
      _showError('Nama panggilan tidak boleh kosong');
      return;
    }
    if (_kelasController.text.trim().isEmpty) {
      _showError('Kelas tidak boleh kosong');
      return;
    }
    if (_selectedDate == null) {
      _showError('Tanggal lahir harus dipilih');
      return;
    }
    if (_selectedGender == null) {
      _showError('Jenis kelamin harus dipilih');
      return;
    }

    setState(() => _isLoading = true);

    final data = CreateStudentData(
      nama: _namaController.text.trim(),
      namaPanggilan: _namaPanggilanController.text.trim(),
      kelas: _kelasController.text.trim(),
      jenisKelamin: _selectedGender!,
      tanggalLahir: _selectedDate!,
      tingkatPendidikan: _selectedEducation,
    );

    final result = await context.read<StudentProvider>().createStudent(data);

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF41B37E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tambah Murid Baru',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProRounded,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Nama Lengkap'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _namaController,
                        hintText: 'Masukkan nama lengkap murid...',
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Nama Panggilan'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _namaPanggilanController,
                        hintText: 'Nama yang akan disapa Cimo...',
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Kelas'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _kelasController,
                        hintText: 'Contoh: 3A, 4B, 5...',
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Tanggal Lahir'),
                      const SizedBox(height: 8),
                      _buildDatePicker(),
                      const SizedBox(height: 16),

                      _buildLabel('Jenis Kelamin'),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedGender,
                        items: _genderOptions,
                        hint: 'Pilih jenis kelamin',
                        onChanged: (value) => setState(() => _selectedGender = value),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Tingkat Pendidikan (Opsional)'),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedEducation,
                        items: _educationOptions,
                        hint: 'Pilih tingkat pendidikan',
                        onChanged: (value) => setState(() => _selectedEducation = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.textHint),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontFamily: AppFonts.sfProRounded,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF41B37E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                fontFamily: AppFonts.sfProRounded,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.sfProRounded,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText}) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontFamily: AppFonts.sfProRounded,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontFamily: AppFonts.sfProRounded, color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF41B37E), width: 2),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('dd MMMM yyyy', 'id').format(_selectedDate!)
                    : 'Pilih tanggal lahir',
                style: TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  fontSize: 14,
                  color: _selectedDate != null ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            const Icon(Icons.calendar_today, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(fontFamily: AppFonts.sfProRounded, color: AppColors.textHint),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHint),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontFamily: AppFonts.sfProRounded,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
