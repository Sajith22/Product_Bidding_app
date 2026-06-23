// ─────────────────────────────────────────────────────────────────────────────
// screens/admin/add_product_screen.dart
// Replaces old add_product_screen.dart — saves to Firestore.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/admin_theme.dart';
import '../../models/app_models.dart';
import '../../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _titleCtrl     = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _priceCtrl     = TextEditingController();
  final _incrementCtrl = TextEditingController();
  final _service       = ProductService();
  final _picker        = ImagePicker();

  DateTime _startTime       = DateTime.now().add(const Duration(hours: 1));
  int _durationHours        = 48;   // default 2 days
  bool _isPublished         = true;
  bool _loading             = false;
  String? _error;

  Uint8List? _imageBytes;
  String? _imageFileName;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _incrementCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null) return;

    setState(() {
      _startTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageFileName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to pick image. Please try again.');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final price = double.parse(_priceCtrl.text.trim());
    final increment = _incrementCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_incrementCtrl.text.trim());

    final product = Product(
      id: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      startingPrice: price,
      currentHighestBid: price,
      startTime: _startTime,
      duration: Duration(hours: _durationHours),
      minIncrement: increment,
      isPublished: _isPublished,
      adminId: uid,
    );

    final id = await _service.createProduct(product);
    if (!mounted) return;

    if (id != null) {
      // Upload image if provided
      if (_imageBytes != null) {
        final url = await _service.uploadProductImageBytes(
          productId: id,
          bytes: _imageBytes!,
          fileName: _imageFileName ?? 'image.jpg',
        );
        if (url != null) {
          await _service.updateProduct(id, {'imageUrl': url});
        }
      }

      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product created successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      if (!mounted) return;
      setState(() => _loading = false);
      setState(() => _error = 'Failed to create product. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Add New Product')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 0 : 16,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    _ErrorBox(_error!),
                    const SizedBox(height: 14),
                  ],

                  _SectionCard(
                    title: 'Product Photo',
                    children: [
                      GestureDetector(
                        onTap: _loading ? null : _pickImage,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _imageBytes != null
                                    ? Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.add_photo_alternate_outlined,
                                                size: 34,
                                                color: AppTheme.textSecondary),
                                            SizedBox(height: 8),
                                            Text(
                                              'Tap to add a photo',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textSecondary),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'JPG/PNG, recommended 1600px+',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.upload_rounded,
                                          size: 16,
                                          color: AppTheme.textSecondary),
                                      SizedBox(width: 6),
                                      Text('Choose',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                              if (_imageBytes != null)
                                Positioned(
                                  left: 10,
                                  top: 10,
                                  child: GestureDetector(
                                    onTap: _loading
                                        ? null
                                        : () => setState(() {
                                              _imageBytes = null;
                                              _imageFileName = null;
                                            }),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppTheme.border),
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          size: 16,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    title: 'Product Details',
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(labelText: 'Product Title *'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Description *',
                            alignLabelWithHint: true),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Description is required'
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    title: 'Bid Configuration',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Starting Price (\$) *',
                                  prefixText: '\$ '),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(v.trim()) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _incrementCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Min Increment (\$)',
                                  prefixText: '\$ '),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Start time picker
                      const Text('Bid Start Time',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickStartTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 18, color: AppTheme.textSecondary),
                              const SizedBox(width: 10),
                              Text(
                                _formatDateTime(_startTime),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const Spacer(),
                              const Icon(Icons.edit_outlined,
                                  size: 16, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Duration slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bidding Duration',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _durationHours >= 24
                                  ? '${(_durationHours / 24).round()} day(s)'
                                  : '$_durationHours hour(s)',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _durationHours.toDouble(),
                        min: 1,
                        max: 168,  // 7 days max
                        divisions: 167,
                        activeColor: AppTheme.primary,
                        onChanged: (v) =>
                            setState(() => _durationHours = v.round()),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('1 hr', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                          Text('7 days', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    title: 'Publishing',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Publish immediately',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  _isPublished
                                      ? 'Visible to all bidders'
                                      : 'Hidden from bidders',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPublished,
                            activeColor: AppTheme.primary,
                            onChanged: (v) =>
                                setState(() => _isPublished = v),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded),
                      label: Text(_loading
                          ? 'Creating...'
                          : 'Create Product'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppTheme.error, fontSize: 13))),
        ],
      ),
    );
  }
}

// Make textMuted accessible from admin_theme — add this if missing in admin_theme.dart
extension AdminThemeExt on AppTheme {
  static const textMuted = Color(0xFF94A3B8);
}
