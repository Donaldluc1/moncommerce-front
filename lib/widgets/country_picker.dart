// lib/widgets/country_picker.dart
import 'package:flutter/material.dart';

class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

class CountryData {
  static final List<Country> countries = [
    Country(name: 'Côte d\'Ivoire', code: 'CI', dialCode: '+225', flag: '🇨🇮'),
    Country(name: 'Sénégal', code: 'SN', dialCode: '+221', flag: '🇸🇳'),
    Country(name: 'Bénin', code: 'BJ', dialCode: '+229', flag: '🇧🇯'),
    Country(name: 'Burkina Faso', code: 'BF', dialCode: '+226', flag: '🇧🇫'),
    Country(name: 'Mali', code: 'ML', dialCode: '+223', flag: '🇲🇱'),
    Country(name: 'Togo', code: 'TG', dialCode: '+228', flag: '🇹🇬'),
    Country(name: 'Niger', code: 'NE', dialCode: '+227', flag: '🇳🇪'),
    Country(name: 'Guinée', code: 'GN', dialCode: '+224', flag: '🇬🇳'),
    Country(name: 'Cameroun', code: 'CM', dialCode: '+237', flag: '🇨🇲'),
    Country(name: 'Congo', code: 'CG', dialCode: '+242', flag: '🇨🇬'),
    Country(name: 'Gabon', code: 'GA', dialCode: '+241', flag: '🇬🇦'),
    Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
  ];

  static Country getDefaultCountry() {
    return countries.firstWhere(
      (country) => country.code == 'CI',
      orElse: () => countries.first,
    );
  }
}

class CountryPickerButton extends StatelessWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;

  const CountryPickerButton({
    super.key,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCountryPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCountry.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              selectedCountry.dialCode,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CountryPickerSheet(
        selectedCountry: selectedCountry,
        onCountrySelected: (country) {
          onCountryChanged(country);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class CountryPickerSheet extends StatefulWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onCountrySelected;

  const CountryPickerSheet({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  String _searchQuery = '';
  List<Country> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = CountryData.countries;
  }

  void _filterCountries(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCountries = CountryData.countries;
      } else {
        _filteredCountries = CountryData.countries.where((country) {
          return country.name.toLowerCase().contains(_searchQuery) ||
              country.dialCode.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Titre
          const Text(
            'Sélectionner un pays',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Champ de recherche
          TextField(
            onChanged: _filterCountries,
            decoration: InputDecoration(
              hintText: 'Rechercher un pays...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),

          // Liste des pays
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;

                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    country.dialCode,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.green : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.green[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () => widget.onCountrySelected(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de champ téléphone avec sélecteur de pays
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String labelText;
  final ValueChanged<Country>? onCountryChanged;
  final Country? initialCountry;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.validator,
    this.labelText = 'Numéro de téléphone',
    this.onCountryChanged,
    this.initialCountry,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? CountryData.getDefaultCountry();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélecteur de pays
        CountryPickerButton(
          selectedCountry: _selectedCountry,
          onCountryChanged: (country) {
            setState(() => _selectedCountry = country);
            widget.onCountryChanged?.call(country);
          },
        ),
        const SizedBox(width: 12),

        // Champ téléphone
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: 'Ex: 0708090102',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }

  // Méthode helper pour obtenir le numéro complet
  String getFullPhoneNumber() {
    String number = widget.controller.text.trim();
    // Retirer le 0 initial si présent
    if (number.startsWith('0')) {
      number = number.substring(1);
    }
    return '${_selectedCountry.dialCode}$number';
  }
}