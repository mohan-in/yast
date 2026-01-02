import 'package:hive/hive.dart';
import 'post.dart';

/// Hive TypeAdapter for the Post class.
/// Since Post has many fields, we manually implement the adapter
/// instead of using code generation for simplicity.
class PostAdapter extends TypeAdapter<Post> {
  @override
  final int typeId = 0;

  @override
  Post read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Post(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      subreddit: fields[3] as String,
      ups: fields[4] as int,
      numComments: fields[5] as int,
      thumbnail: fields[6] as String?,
      imageUrl: fields[7] as String?,
      permalink: fields[8] as String,
      content: fields[9] as String,
      createdUtc: fields[10] as double,
      images: (fields[11] as List).cast<String>(),
      isVideo: fields[12] as bool,
      videoUrl: fields[13] as String?,
      isYoutube: fields[14] as bool,
      youtubeId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Post obj) {
    writer
      ..writeByte(16) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.subreddit)
      ..writeByte(4)
      ..write(obj.ups)
      ..writeByte(5)
      ..write(obj.numComments)
      ..writeByte(6)
      ..write(obj.thumbnail)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.permalink)
      ..writeByte(9)
      ..write(obj.content)
      ..writeByte(10)
      ..write(obj.createdUtc)
      ..writeByte(11)
      ..write(obj.images)
      ..writeByte(12)
      ..write(obj.isVideo)
      ..writeByte(13)
      ..write(obj.videoUrl)
      ..writeByte(14)
      ..write(obj.isYoutube)
      ..writeByte(15)
      ..write(obj.youtubeId);
  }
}
