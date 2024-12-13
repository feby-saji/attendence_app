formatDate(DateTime date) {
  String day = date.day.toString().padLeft(2, '0');
  String month = date.month.toString().padLeft(2, '0');
  String year = date.year.toString().substring(2);

  // Format the date as dd/mm/yy
  return '$day/$month/$year';
}
