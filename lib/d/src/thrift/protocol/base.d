/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/**
 * Defines the basic interface for a Thrift protocol and associated exception
 * types.
 *
 * Most parts of the protocol API are typically not used in client code, as
 * the actual serialization code is generated by thrift.codegen.* – the only
 * interesting thing usually is that there are protocols which can be created
 * from transports and passed around.
 */
module thrift.protocol.base;

import thrift.base;
import thrift.transport.base;

/**
 * The field types Thrift protocols support.
 */
enum TType : byte {
  STOP   = 0, /// Used to mark the end of a sequence of fields.
  VOID   = 1, ///
  BOOL   = 2, ///
  BYTE   = 3, ///
  DOUBLE = 4, ///
  I16    = 6, ///
  I32    = 8, ///
  I64    = 10, ///
  STRING = 11, ///
  STRUCT = 12, ///
  MAP    = 13, ///
  SET    = 14, ///
  LIST   = 15 ///
}

/**
 * Types of Thrift RPC messages.
 */
enum TMessageType : byte {
  CALL = 1, /// Call of a normal, two-way RPC method.
  REPLY = 2, /// Reply to a normal method call.
  EXCEPTION = 3, /// Reply to a method call if target raised a TApplicationException.
  ONEWAY = 4 /// Call of a one-way RPC method which is not followed by a reply.
}

/**
 * Descriptions of Thrift entities.
 */
struct TField {
  string name;
  TType type;
  short id;
}

/// ditto
struct TList {
  TType elemType;
  size_t size;
}

/// ditto
struct TMap {
  TType keyType;
  TType valueType;
  size_t size;
}

/// ditto
struct TMessage {
  string name;
  TMessageType type;
  int seqid;
}

/// ditto
struct TSet {
  TType elemType;
  size_t size;
}

/// ditto
struct TStruct {
  string name;
}

/**
 * Interface for a Thrift protocol implementation. Essentially, it defines
 * a way of reading and writing all the base types, plus a mechanism for
 * writing out structs with indexed fields.
 *
 * TProtocol objects should not be shared across multiple encoding contexts,
 * as they may need to maintain internal state in some protocols (e.g. JSON).
 * Note that is is acceptable for the TProtocol module to do its own internal
 * buffered reads/writes to the underlying TTransport where appropriate (i.e.
 * when parsing an input XML stream, reading could be batched rather than
 * looking ahead character by character for a close tag).
 */
interface TProtocol {
  /// The underlying transport used by the protocol.
  TTransport transport() @property;

  /*
   * Writing methods.
   */

  void writeBool(bool b); ///
  void writeByte(byte b); ///
  void writeI16(short i16); ///
  void writeI32(int i32); ///
  void writeI64(long i64); ///
  void writeDouble(double dub); ///
  void writeString(string str); ///
  void writeBinary(ubyte[] buf); ///

  void writeMessageBegin(TMessage message); ///
  void writeMessageEnd(); ///
  void writeStructBegin(TStruct tstruct); ///
  void writeStructEnd(); ///
  void writeFieldBegin(TField field); ///
  void writeFieldEnd(); ///
  void writeFieldStop(); ///
  void writeListBegin(TList list); ///
  void writeListEnd(); ///
  void writeMapBegin(TMap map); ///
  void writeMapEnd(); ///
  void writeSetBegin(TSet set); ///
  void writeSetEnd(); ///

  /*
   * Reading methods.
   */

  bool readBool(); ///
  byte readByte(); ///
  short readI16(); ///
  int readI32(); ///
  long readI64(); ///
  double readDouble(); ///
  string readString(); ///
  ubyte[] readBinary(); ///

  TMessage readMessageBegin(); ///
  void readMessageEnd(); ///
  TStruct readStructBegin(); ///
  void readStructEnd(); ///
  TField readFieldBegin(); ///
  void readFieldEnd(); ///
  TList readListBegin(); ///
  void readListEnd(); ///
  TMap readMapBegin(); ///
  void readMapEnd(); ///
  TSet readSetBegin(); ///
  void readSetEnd(); ///

  /**
   * Reset any internal state back to a blank slate, if the protocol is
   * stateful.
   */
  void reset();
}

/**
 * true if T is a TProtocol.
 */
template isTProtocol(T) {
  enum isTProtocol = is(T : TProtocol);
}

unittest {
  static assert(isTProtocol!TProtocol);
  static assert(!isTProtocol!void);
}

/**
 * Creates a protocol operating on a given transport.
 */
interface TProtocolFactory {
  ///
  TProtocol getProtocol(TTransport trans);
}

/**
 * A protocol-level exception.
 */
class TProtocolException : TException {
  /// The possible exception types.
  enum Type {
    UNKNOWN, ///
    INVALID_DATA, ///
    NEGATIVE_SIZE, ///
    SIZE_LIMIT, ///
    BAD_VERSION, ///
    NOT_IMPLEMENTED, ///
    DEPTH_LIMIT ///
  }

  ///
  this(Type type, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    static string msgForType(Type type) {
      switch (type) {
        case Type.UNKNOWN: return "Unknown protocol exception";
        case Type.INVALID_DATA: return "Invalid data";
        case Type.NEGATIVE_SIZE: return "Negative size";
        case Type.SIZE_LIMIT: return "Exceeded size limit";
        case Type.BAD_VERSION: return "Invalid version";
        case Type.NOT_IMPLEMENTED: return "Not implemented";
        case Type.DEPTH_LIMIT: return "Exceeded size limit";
        default: return "(Invalid exception type)";
      }
    }
    this(msgForType(type), type, file, line, next);
  }

  ///
  this(string msg, string file = __FILE__, size_t line = __LINE__,
    Throwable next = null)
  {
    this(msg, Type.UNKNOWN, file, line, next);
  }

  ///
  this(string msg, Type type, string file = __FILE__, size_t line = __LINE__,
    Throwable next = null)
  {
    super(msg, file, line, next);
    type_ = type;
  }

  ///
  Type type() const @property {
    return type_;
  }

protected:
  Type type_;
}

/**
 * Skips a field of the given type on the protocol.
 *
 * The main purpose of skip() is to allow treating struct and container types,
 * (where multiple primitive types have to be skipped) the same as scalar types
 * in generated code.
 */
void skip(Protocol)(Protocol prot, TType type) if (is(Protocol : TProtocol)) {
  final switch (type) {
    case TType.BOOL:
      prot.readBool();
      break;

    case TType.BYTE:
      prot.readByte();
      break;

    case TType.I16:
      prot.readI16();
      break;

    case TType.I32:
      prot.readI32();
      break;

    case TType.I64:
      prot.readI64();
      break;

    case TType.DOUBLE:
      prot.readDouble();
      break;

    case TType.STRING:
      prot.readBinary();
      break;

    case TType.STRUCT:
      prot.readStructBegin();
      while (true) {
        auto f = prot.readFieldBegin();
        if (f.type == TType.STOP) break;
        skip(prot, f.type);
        prot.readFieldEnd();
      }
      prot.readStructEnd();
      break;

    case TType.LIST:
      auto l = prot.readListBegin();
      foreach (i; 0 .. l.size) {
        skip(prot, l.elemType);
      }
      prot.readListEnd();
      break;

    case TType.MAP:
      auto m = prot.readMapBegin();
      foreach (i; 0 .. m.size) {
        skip(prot, m.keyType);
        skip(prot, m.valueType);
      }
      prot.readMapEnd();
      break;

    case TType.SET:
      auto s = prot.readSetBegin();
      foreach (i; 0 .. s.size) {
        skip(prot, s.elemType);
      }
      prot.readSetEnd();
      break;
    case TType.STOP: goto case;
    case TType.VOID:
      assert(false, "Invalid field type passed.");
  }
}

/**
 * Application-level exception.
 *
 * It is thrown if an RPC call went wrong on the application layer, e.g. if
 * the receiver does not know the method name requested or a method invoked by
 * the service processor throws an exception not part of the Thrift API.
 */
class TApplicationException : TException {
  /// The possible exception types.
  enum Type {
    UNKNOWN = 0, ///
    UNKNOWN_METHOD = 1, ///
    INVALID_MESSAGE_TYPE = 2, ///
    WRONG_METHOD_NAME = 3, ///
    BAD_SEQUENCE_ID = 4, ///
    MISSING_RESULT = 5, ///
    INTERNAL_ERROR = 6, ///
    PROTOCOL_ERROR = 7, ///
    INVALID_TRANSFORM = 8, ///
    INVALID_PROTOCOL = 9, ///
    UNSUPPORTED_CLIENT_TYPE = 10 ///
  }

  ///
  this(Type type, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    static string msgForType(Type type) {
      switch (type) {
        case Type.UNKNOWN: return "Unknown application exception";
        case Type.UNKNOWN_METHOD: return "Unknown method";
        case Type.INVALID_MESSAGE_TYPE: return "Invalid message type";
        case Type.WRONG_METHOD_NAME: return "Wrong method name";
        case Type.BAD_SEQUENCE_ID: return "Bad sequence identifier";
        case Type.MISSING_RESULT: return "Missing result";
        case Type.INTERNAL_ERROR: return "Internal error";
        case Type.PROTOCOL_ERROR: return "Protocol error";
        case Type.INVALID_TRANSFORM: return "Invalid transform";
        case Type.INVALID_PROTOCOL: return "Invalid protocol";
        case Type.UNSUPPORTED_CLIENT_TYPE: return "Unsupported client type";
        default: return "(Invalid exception type)";
      }
    }
    this(msgForType(type), type, file, line, next);
  }

  ///
  this(string msg, string file = __FILE__, size_t line = __LINE__,
    Throwable next = null)
  {
    this(msg, Type.UNKNOWN, file, line, next);
  }

  ///
  this(string msg, Type type, string file = __FILE__, size_t line = __LINE__,
    Throwable next = null)
  {
    super(msg, file, line, next);
    type_ = type;
  }

  ///
  Type type() @property const {
    return type_;
  }

  // TODO: Replace hand-written read()/write() with thrift.codegen templates.

  ///
  void read(TProtocol iprot) {
    iprot.readStructBegin();
    while (true) {
      auto f = iprot.readFieldBegin();
      if (f.type == TType.STOP) break;

      switch (f.id) {
        case 1:
          if (f.type == TType.STRING) {
            msg = iprot.readString();
          } else {
            skip(iprot, f.type);
          }
          break;
        case 2:
          if (f.type == TType.I32) {
            type_ = cast(Type)iprot.readI32();
          } else {
            skip(iprot, f.type);
          }
          break;
        default:
          skip(iprot, f.type);
          break;
      }
    }
    iprot.readStructEnd();
  }

  ///
  void write(TProtocol oprot) const {
    oprot.writeStructBegin(TStruct("TApplicationException"));

    if (msg != null) {
      oprot.writeFieldBegin(TField("message", TType.STRING, 1));
      oprot.writeString(msg);
      oprot.writeFieldEnd();
    }

    oprot.writeFieldBegin(TField("type", TType.I32, 2));
    oprot.writeI32(type_);
    oprot.writeFieldEnd();

    oprot.writeFieldStop();
    oprot.writeStructEnd();
  }

private:
  Type type_;
}
