extension String {
    func indent(_ num: Int, includeFirst: Bool = true) -> String {
        let indent = String.init(repeating: "    ", count: num)
        var firstLine = true
        return self.split(separator: "\n").map { line in
            var result = line
            if firstLine {
                firstLine == false
            }
            if !line.isEmpty {
                if !firstLine || includeFirst {
                    result = indent + line
                }
            }
            firstLine = false
            return result
        }.joined(separator: "\n")
    }
}
