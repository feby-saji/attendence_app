formatDate(DateTime date) {
  DateTime now = DateTime.now();

  String day = now.day.toString().padLeft(2, '0');
  String month = now.month.toString().padLeft(2, '0');
  String year = now.year.toString().substring(2);

  // Format the date as dd/mm/yy
  return '$day/$month/$year';
}
