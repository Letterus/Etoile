include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = libEtoileSerialize

libEtoileSerialize_OBJC_FILES = \
					ESCORefTable.m \
					ETDeserializer.m \
					ETDeserializerBackendBinary.m \
					ETDeserializerBackendXML.m \
					ETSerializer.m \
					ETSerializerBackendBinary.m \
					ETSerializerBackendExample.m \
					ETSerializerBackendXML.m \
					ETSerializerNullBackend.m \
					ETXMLDeserializationHandler.m \
					GSArray+ETSerializable.m \
					GSDictionary+ETSerializable.m \
					GSSet+ETSerializable.m \
					GSMutableString+ETSerializable.m \
					NSData+ETSerializable.m \
					NSInvocation+ETSerializable.m \
					NSString+Conversions.m \
					NSURL+ETSerializable.m \
					ETSerialObjectBuffer.m\
					ETSerialObjectBundle.m\
					ETSerialObjectStdout.m\
					ETSerialObjectSocket.m\
					NSData+Varint.m\
					NSNumber+Varint.m\
					StringMap.m

ifeq ($(test), yes)
libEtoileSerialize_OBJC_FILES +=\
					ESProxy.m \
					ETSerializerTest.m 
endif

# Extra CPPFLAGS necessary to compile on Linux
libEtoileSerialize_CPPFLAGS += -D_GNU_SOURCE=1 -D_XOPEN_SOURCE=600 -D__BSD_VISIBLE -I../Headers
libEtoileSerialize_OBJCFLAGS += -g -std=c99 #-Werror

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include ../GNUmakefile.postamble
