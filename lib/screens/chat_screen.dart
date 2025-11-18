import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart'; // 🆕 Import để cập nhật status

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String receiverName;
  final String receiverId;
  final String? applicationId; // 🆕 Thêm applicationId (optional)
  final bool isRecruiter;      // 🆕 Thêm flag để biết user là Recruiter hay Applicant

  const ChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.receiverName,
    required this.receiverId,
    this.applicationId,         // 🆕
    this.isRecruiter = false,   // 🆕 Mặc định là Applicant
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final JobService _jobService = JobService(); // 🆕
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String _currentUserId;
  String _currentApplicationStatus = 'pending'; // 🆕 Trạng thái hiện tại của application

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.currentUser?.uid ?? '';
    _loadApplicationStatus(); // 🆕 Tải trạng thái application
  }

  // 🆕 TẢI TRẠNG THÁI APPLICATION
  Future<void> _loadApplicationStatus() async {
    if (widget.applicationId != null && widget.applicationId!.isNotEmpty) {
      try {
        DocumentSnapshot appDoc = await FirebaseFirestore.instance
            .collection('applications')
            .doc(widget.applicationId)
            .get();
        
        if (appDoc.exists && mounted) {
          setState(() {
            _currentApplicationStatus = appDoc.get('status') ?? 'pending';
          });
        }
      } catch (e) {
        print('❌ Lỗi khi tải trạng thái application: $e');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🆕 HÀM CẬP NHẬT TRẠNG THÁI APPLICATION
  Future<void> _updateApplicationStatus(String newStatus) async {
    if (widget.applicationId == null || widget.applicationId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy đơn ứng tuyển.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Hiển thị dialog xác nhận
    String actionText = newStatus == 'reviewed' ? 'duyệt' : 'từ chối';
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận ${actionText}'),
        content: Text('Bạn có chắc muốn ${actionText} ứng viên này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'reviewed' ? Colors.green : Colors.red,
            ),
            child: Text(newStatus == 'reviewed' ? 'Duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Hiện loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      bool success = await _jobService.updateApplicationStatus(widget.applicationId!, newStatus);
      
      if (mounted) {
        Navigator.pop(context); // Tắt loading

        if (success) {
          setState(() {
            _currentApplicationStatus = newStatus;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã ${actionText} ứng viên thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi ${actionText} ứng viên.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && _currentUserId.isNotEmpty) {
      final message = ChatMessage(
        senderId: _currentUserId,
        receiverId: widget.receiverId,
        text: text,
        timestamp: Timestamp.now(),
      );

      _messageController.clear();
      _scrollToBottom();

      bool success = await _chatService.sendMessage(widget.chatRoomId, message);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi tin nhắn thất bại.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            // 🆕 Hiển thị trạng thái application cho Recruiter
            if (widget.isRecruiter)
              Text(
                _getStatusText(_currentApplicationStatus),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 1,
        // 🆕 THÊM NÚT DUYỆT/TỪ CHỐI CHO RECRUITER
        actions: widget.isRecruiter && _currentApplicationStatus == 'pending'
            ? [
                // Nút Duyệt
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Duyệt ứng viên',
                  onPressed: () => _updateApplicationStatus('reviewed'),
                ),
                // Nút Từ chối
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: 'Từ chối ứng viên',
                  onPressed: () => _updateApplicationStatus('rejected'),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // 🆕 BANNER TRẠNG THÁI (nếu đã duyệt hoặc từ chối)
          if (_currentApplicationStatus != 'pending')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: _getStatusColor(_currentApplicationStatus).withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentApplicationStatus == 'reviewed' 
                        ? Icons.check_circle 
                        : Icons.cancel,
                    color: _getStatusColor(_currentApplicationStatus),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(_currentApplicationStatus),
                    style: TextStyle(
                      color: _getStatusColor(_currentApplicationStatus),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Phần hiển thị tin nhắn
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải tin nhắn: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có tin nhắn nào.'));
                }

                final messagesDocs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: messagesDocs.length,
                  itemBuilder: (context, index) {
                    var messageData = messagesDocs[index].data() as Map<String, dynamic>;
                    ChatMessage message = ChatMessage.fromMap(messageData);
                    bool isMe = message.senderId == _currentUserId;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // Phần nhập liệu
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
          decoration: BoxDecoration(
            color: isMe ? Colors.orange[600] : Colors.grey[300],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15.0),
              topRight: const Radius.circular(15.0),
              bottomLeft: Radius.circular(isMe ? 15.0 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 15.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 3.0,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                minLines: 1,
                maxLines: 5,
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: Icon(Icons.send_rounded, color: Colors.orange[700]),
              onPressed: _sendMessage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 24,
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 Helper functions
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Đang chờ duyệt';
      case 'reviewed': return 'Đã duyệt';
      case 'rejected': return 'Đã từ chối';
      default: return 'Không rõ';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange[600]!;
      case 'reviewed': return Colors.green[600]!;
      case 'rejected': return Colors.red[600]!;
      default: return Colors.grey[500]!;
    }
  }
}