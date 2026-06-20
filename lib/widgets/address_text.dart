import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class AddressText extends StatefulWidget {
  final String address;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;

  const AddressText({
    super.key,
    required this.address,
    this.style,
    this.overflow,
    this.maxLines,
  });

  @override
  State<AddressText> createState() => _AddressTextState();
}

class _AddressTextState extends State<AddressText> {
  late String _displayAddress;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _displayAddress = widget.address;
    _checkAndGeocode();
  }

  @override
  void didUpdateWidget(covariant AddressText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _displayAddress = widget.address;
      _checkAndGeocode();
    }
  }

  Future<void> _checkAndGeocode() async {
    if (_displayAddress.contains("Koordinat:")) {
      final index = _displayAddress.indexOf("Koordinat:");
      final coordsStr = _displayAddress.substring(index + "Koordinat:".length).trim();
      final parts = coordsStr.split(",");
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          if (mounted) {
            setState(() {
              _isGeocoding = true;
            });
          }
          try {
            final placemarks = await placemarkFromCoordinates(lat, lng);
            if (placemarks.isNotEmpty && mounted) {
              final place = placemarks.first;
              final List<String> addressParts = [];
              if (place.street != null && place.street!.isNotEmpty) {
                addressParts.add(place.street!);
              }
              if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                addressParts.add(place.subLocality!);
              }
              if (place.locality != null && place.locality!.isNotEmpty) {
                addressParts.add(place.locality!);
              }
              if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
                addressParts.add(place.subAdministrativeArea!);
              }
              
              if (addressParts.isNotEmpty && mounted) {
                setState(() {
                  _displayAddress = addressParts.join(', ');
                  _isGeocoding = false;
                });
                return;
              }
            }
          } catch (e) {
            print("Error reverse geocoding in AddressText: $e");
          }
          if (mounted) {
            setState(() {
              _isGeocoding = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isGeocoding
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2DAAC8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _displayAddress,
                  style: widget.style?.copyWith(color: Colors.grey) ?? const TextStyle(color: Colors.grey),
                  overflow: widget.overflow,
                  maxLines: widget.maxLines,
                ),
              ),
            ],
          )
        : Text(
            _displayAddress,
            style: widget.style,
            overflow: widget.overflow,
            maxLines: widget.maxLines,
          );
  }
}
