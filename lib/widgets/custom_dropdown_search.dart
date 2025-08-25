import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CustomDropdownSearch<T> extends StatelessWidget {
  final String labelText;
  final List<T> items;
  final T? selectedItem;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final Future<List<T>> Function(String?)? asyncItems;
  final bool showSearchBox;
  final String Function(T)? itemAsString;
  final bool Function(T, T)? compareFn;

  const CustomDropdownSearch({
    super.key,
    required this.labelText,
    this.items = const [],
    this.selectedItem,
    this.onChanged,
    this.validator,
    this.asyncItems,
    this.showSearchBox = true,
    this.itemAsString,
    this.compareFn,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      T == String || itemAsString != null,
      'itemAsString must be provided if T is not String',
    );
    assert(
      T == String || compareFn != null,
      'compareFn must be provided if T is not String when showSelectedItems is true',
    );

    final Color primaryColor = Theme.of(context).primaryColor;
    final Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: DropdownSearch<T>(
        selectedItem: selectedItem,
        asyncItems: asyncItems,
        items: items,
        itemAsString: itemAsString,
        onChanged: onChanged,
        compareFn: compareFn,
        validator: validator,
        popupProps: PopupProps.dialog(
          showSearchBox: showSearchBox,
          showSelectedItems: true,
          isFilterOnline: true, // <-- ini WAJIB agar search selalu panggil asyncItems
          searchDelay: const Duration(milliseconds: 500),
          
          dialogProps: DialogProps(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            insetPadding: const EdgeInsets.fromLTRB(16, 24, 16, 60),
          ),
          title: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              labelText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ), 
          ),
         
          fit: FlexFit.loose,
          
          emptyBuilder:
              (context, searchEntry) => const Center(
                child: Padding(
                  
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Data tidak ditemukan',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          loadingBuilder:
              (context, searchEntry) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Cari $labelText...",
              prefixIcon: Icon(Icons.search, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          itemBuilder: (context, item, isSelected) {
            final String displayString = itemAsString!.call(item);
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayString,
                style: TextStyle(
                  color: isSelected ? primaryColor : textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            );
          },
        ),

        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: labelText,
            hintText: "Pilih $labelText",
            labelStyle: TextStyle(color: Colors.grey.shade600),
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2.5),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: Icon(Icons.arrow_drop_down, color: primaryColor),
          ),
        ),
      ),
    );
  }
}
