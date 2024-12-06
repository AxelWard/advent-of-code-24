const std = @import("std");

pub fn arrayListContainsValue(comptime T: type, comptime EqFn: anytype) (fn (list: *std.ArrayList(T), value: T) bool) {
    return struct {
        fn checkContains(list: *std.ArrayList(T), value: T) bool {
            for (0..list.items.len) |index| {
                if (EqFn(list.items[index], value)) return true;
            }

            return false;
        }
    }.checkContains;
}
