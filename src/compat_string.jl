module CompatString
    typealias String Base.UTF8String
    export String
end
import .CompatString.String
