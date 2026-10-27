class DownloadTab {
  final String id;
  final String title;
  final String? assignedTaskId;
  final bool isClosable;

  const DownloadTab({
    required this.id,
    required this.title,
    this.assignedTaskId,
    this.isClosable = true,
  });

  DownloadTab copyWith({
    String? id,
    String? title,
    String? assignedTaskId,
    bool? isClosable,
  }) {
    return DownloadTab(
      id: id ?? this.id,
      title: title ?? this.title,
      assignedTaskId: assignedTaskId ?? this.assignedTaskId,
      isClosable: isClosable ?? this.isClosable,
    );
  }
}
