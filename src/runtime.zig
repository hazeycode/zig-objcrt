//! This module provides type-safe bindings to the API defined in objc/runtime.h
// TODO(hazeycode): add missing definitions

const objc = @import("objc.zig");
const Class = objc.Class;

const c = @import("c.zig");

pub const Error = error{
    ClassNotRegisteredWithRuntime,
    FailedToAllocateClassPair,
};

// ----- Working with instances -----

// ----- Obtaining Class definitions ----

/// Returns the class definition of a specified class, or an error if the class is not registered
/// with the Objective-C runtime.
/// 
/// @param name The name of the class to look up.
/// 
/// @note \c objc_getClass is different from \c objc_lookUpClass in that if the class
///  is not registered, \c objc_getClass calls the class handler callback and then checks
///  a second time to see whether the class is registered. \c objc_lookUpClass does 
///  not call the class handler callback.
/// 
/// @warning Earlier implementations of this function (prior to OS X v10.0)
///  terminate the program if the class does not exist.
pub fn getClass(class_name: [:0]const u8) Error!Class {
    return c.objc_getClass(class_name) orelse Error.ClassNotRegisteredWithRuntime;
}

/// Returns the metaclass definition of a specified class, or an error if the class is not registered
/// with the Objective-C runtime.
/// 
/// @param name The name of the class to look up.
/// 
/// @note If the definition for the named class is not registered, this function calls the class handler
///  callback and then checks a second time to see if the class is registered. However, every class
///  definition must have a valid metaclass definition, and so the metaclass definition is always returned,
///  whether it’s valid or not.
pub fn getMetaClass(class_name: [:0]const u8) Error!Class {
    return c.objc_getMetaClass(class_name) orelse Error.ClassNotRegisteredWithRuntime;
}

/// Returns the class definition of a specified class, or null if the class is not registered
/// with the Objective-C runtime
/// 
/// @param name The name of the class to look up.
/// 
/// @note \c objc_getClass is different from this function in that if the class is not
///  registered, \c objc_getClass calls the class handler callback and then checks a second
///  time to see whether the class is registered. This function does not call the class handler callback.
pub fn lookUpClass(class_name: [:0]const u8) ?Class {
    return c.objc_lookUpClass(class_name);
}

// ----- Adding Classes -----

/// Creates a new class and metaclass.
/// 
/// @param superclass The class to use as the new class's superclass, or nulll to create a new root class.
/// @param name The string to use as the new class's name. The string will be copied.
/// @param extraBytes The number of bytes to allocate for indexed ivars at the end of 
///  the class and metaclass objects. This should usually be \c 0.
/// 
/// @return The new class, or an error if the class could not be created (for example, the desired name is already in use).
/// 
/// @note You can get a pointer to the new metaclass by calling \c object_getClass(newClass).
/// @note To create a new class, start by calling \c objc_allocateClassPair. 
///  Then set the class's attributes with functions like \c class_addMethod and \c class_addIvar.
///  When you are done building the class, call \c objc_registerClassPair. The new class is now ready for use.
/// @note Instance methods and instance variables should be added to the class itself. 
///  Class methods should be added to the metaclass.
pub fn allocateClassPair(superclass: ?Class, class_name: [:0]const u8) Error!Class {
    return c.objc_allocateClassPair(superclass, class_name, 0) orelse Error.FailedToAllocateClassPair;
}

/// Registers a class that was allocated using \c objc_allocateClassPair.
/// 
/// @param cls The class you want to register.
pub fn registerClass(class: Class) void {
    c.objc_registerClassPair(class);
}

/// Destroy a class and its associated metaclass. 
/// 
/// @param cls The class to be destroyed. It must have been allocated with 
///  \c objc_allocateClassPair
/// 
/// @warning Do not call if instances of this class or a subclass exist.
pub fn disposeClassPair(class: Class) void {
    c.objc_disposeClassPair(class);
}
