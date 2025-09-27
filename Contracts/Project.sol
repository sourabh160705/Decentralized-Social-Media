// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DecentralizedSocialMedia
 * @dev A blockchain-based social media platform where users can create posts, 
 * like content, and tip creators with cryptocurrency
 */
contract DecentralizedSocialMedia {
    
    // Post structure
    struct Post {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        uint256 likes;
        uint256 tips;
        bool exists;
    }
    
    // User profile structure
    struct UserProfile {
        string username;
        string bio;
        uint256 totalPosts;
        uint256 totalLikes;
        uint256 totalTipsReceived;
        bool exists;
    }
    
    // State variables
    mapping(uint256 => Post) public posts;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => mapping(address => bool)) public postLikes;
    mapping(address => uint256[]) public userPosts;
    
    uint256 public nextPostId = 1;
    uint256 public totalPosts = 0;
    
    // Events
    event ProfileCreated(address indexed user, string username);
    event PostCreated(uint256 indexed postId, address indexed author, string content);
    event PostLiked(uint256 indexed postId, address indexed liker);
    event PostTipped(uint256 indexed postId, address indexed tipper, uint256 amount);
    
    // Modifiers
    modifier hasProfile() {
        require(userProfiles[msg.sender].exists, "User profile does not exist");
        _;
    }
    
    modifier postExists(uint256 _postId) {
        require(posts[_postId].exists, "Post does not exist");
        _;
    }
    
    /**
     * @dev Core Function 1: Create User Profile
     * @param _username The username for the profile
     * @param _bio The bio description for the profile
     */
    function createProfile(string memory _username, string memory _bio) public {
        require(!userProfiles[msg.sender].exists, "Profile already exists");
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(bytes(_username).length <= 50, "Username too long");
        require(bytes(_bio).length <= 200, "Bio too long");
        
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            totalPosts: 0,
            totalLikes: 0,
            totalTipsReceived: 0,
            exists: true
        });
        
        emit ProfileCreated(msg.sender, _username);
    }
    
    /**
     * @dev Core Function 2: Create Post
     * @param _content The content of the post
     */
    function createPost(string memory _content) public hasProfile {
        require(bytes(_content).length > 0, "Post content cannot be empty");
        require(bytes(_content).length <= 500, "Post content too long");
        
        uint256 postId = nextPostId;
        
        posts[postId] = Post({
            id: postId,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            likes: 0,
            tips: 0,
            exists: true
        });
        
        userPosts[msg.sender].push(postId);
        userProfiles[msg.sender].totalPosts++;
        
        nextPostId++;
        totalPosts++;
        
        emit PostCreated(postId, msg.sender, _content);
    }
    
    /**
     * @dev Core Function 3: Like Post and Tip Creator
     * @param _postId The ID of the post to like and tip
     */
    function likeAndTipPost(uint256 _postId) public payable hasProfile postExists(_postId) {
        require(!postLikes[_postId][msg.sender], "Already liked this post");
        require(posts[_postId].author != msg.sender, "Cannot like your own post");
        
        // Like the post
        postLikes[_postId][msg.sender] = true;
        posts[_postId].likes++;
        userProfiles[posts[_postId].author].totalLikes++;
        
        emit PostLiked(_postId, msg.sender);
        
        // Handle tip if sent
        if (msg.value > 0) {
            posts[_postId].tips += msg.value;
            userProfiles[posts[_postId].author].totalTipsReceived += msg.value;
            
            // Transfer tip to post author
            payable(posts[_postId].author).transfer(msg.value);
            
            emit PostTipped(_postId, msg.sender, msg.value);
        }
    }
    
    // View functions
    function getPost(uint256 _postId) public view returns (Post memory) {
        require(posts[_postId].exists, "Post does not exist");
        return posts[_postId];
    }
    
    function getUserProfile(address _user) public view returns (UserProfile memory) {
        require(userProfiles[_user].exists, "User profile does not exist");
        return userProfiles[_user];
    }
    
    function getUserPosts(address _user) public view returns (uint256[] memory) {
        return userPosts[_user];
    }
    
    function hasUserLikedPost(uint256 _postId, address _user) public view returns (bool) {
        return postLikes[_postId][_user];
    }
    
    function getLatestPosts(uint256 _count) public view returns (uint256[] memory) {
        require(_count > 0, "Count must be greater than 0");
        
        uint256 count = _count > totalPosts ? totalPosts : _count;
        uint256[] memory latestPosts = new uint256[](count);
        
        uint256 currentId = nextPostId - 1;
        uint256 found = 0;
        
        while (found < count && currentId >= 1) {
            if (posts[currentId].exists) {
                latestPosts[found] = currentId;
                found++;
            }
            currentId--;
        }
        
        return latestPosts;
    }
}
