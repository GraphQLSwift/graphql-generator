extension String {
    func indent(_ num: Int, includeFirst: Bool = true) -> String {
        let indent = String.init(repeating: "    ", count: num)
        let body = self.replacingOccurrences(of: "\n", with: "\n" + indent)
        if includeFirst {
            return indent + body
        } else {
            return body
        }
    }
}
