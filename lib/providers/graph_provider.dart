import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';
import 'package:graph_maker_app_2/services/graph_storage_service.dart';

import '../models/edge.dart';
import '../models/matrix_data.dart';

class GraphProvider extends ChangeNotifier{
  Graph _graph = Graph();
  final GraphStorageService _storage = GraphStorageService();
  static const int _maxHistory = 20;
  final List<Graph> _history = [];
  final List<Graph> _future = [];
  final GraphRules rules;
  late String _savedJson;

  GraphProvider({Graph? initialGraph, GraphRules? graphRules}) : _graph = initialGraph?? Graph(), rules = graphRules?? DefaultRules() {
    _savedJson = _currentJson;
  }

  String get _currentJson => jsonEncode(_graph.toJson());

  bool get hasUnsavedChanges => _graph.nodes.isNotEmpty && _currentJson != _savedJson;

  Graph graphGetter(){
    return _graph;
  }

  Graph snapshot(){
    return _graph.clone();
  }

  int _layoutVersion = 0;

  int get layoutVersion => _layoutVersion;

  void replaceGraph(Graph newGraph){
    _pushHistory();
    _graph = newGraph.clone();
    _layoutVersion++;
    notifyListeners();
  }

  String? addNode(double x,double y, {String? name}){
    String? message = rules.checkAddNode(_graph, x, y);
    if(message != null) return message;
    if(name != null){
      message = rules.checkNodeName(_graph, null, name);
      if(message != null) return message;
      name = rules.normalizeNodeName(name);
    }
    _pushHistory();
    _graph.addNode(x, y, name: name);
    notifyListeners();
    return null;
  }

  String? removeNode(String id){
    String? message = rules.checkRemoveNode(_graph, id);
    if(message != null) return message;
    _pushHistory();
    _graph.removeNode(id);
    notifyListeners();
    return null;
  }

  String? addEdge(String sourceNode,String targetNode, double weight, bool directed) {
    String? message = rules.checkAddEdge(_graph, sourceNode, targetNode, directed);
    if(message != null) return message;
    _pushHistory();
    Edge? reverse = _graph.findReverseEdge(sourceNode, targetNode);
    if(reverse != null && !directed) _graph.removeEdge(reverse.id);
    _graph.addEdge(sourceNode, targetNode, weight, directed: directed);
    notifyListeners();
    return null;
  }

  String? removeEdge(String id){
    String? message = rules.checkRemoveEdge(_graph, id);
    if(message != null) return message;
    _pushHistory();
    _graph.removeEdge(id);
    notifyListeners();
    return null;
  }

  void renameNode(String id, String newName){
    _pushHistory();
    _graph.renameNode(id, newName);
    notifyListeners();
  }

  void recolorNode(String id, int color){
    _pushHistory();
    _graph.recolorNode(id, color);
    notifyListeners();
  }

  String? updateNode(String id,{String? newName, int? newColor}){
    if(newName != null){
      String? message = rules.checkNodeName(_graph, id, newName);
      if(message != null) return message;
      newName = rules.normalizeNodeName(newName);
    }
    _pushHistory();
    if(newName != null) _graph.renameNode(id, newName);
    if(newColor != null) _graph.recolorNode(id, newColor);
    notifyListeners();
    return null;
  }

  void updateEdgeWeight(String id, double newWeight) {
    _pushHistory();
    _graph.updateEdgeWeight(id, newWeight);
    notifyListeners();
  }

  String findEdgeAt(double x, double y, {double tolerance = 10}) {
      return _graph.findEdgeAt(x, y, tolerance: tolerance);
  }

  Edge? findReverseEdge(String sourceNode, String targetNode){
    return _graph.findReverseEdge(sourceNode, targetNode);
  }

  String? checkEdgeEndpoints(String sourceId, String targetId){
    return rules.checkEdgeEndpoints(_graph, sourceId, targetId);
  }

  List<String> validateGraph(){
    return rules.validateGraph(_graph);
  }

  List<List<double>> adjacencyMatrix(MatrixData matrixData){
      return _graph.adjacencyMatrix(matrixData);
  }

  MatrixData buildMatrixData(){
      return _graph.buildMatrixData();
  }

  String graphSummaryJson() {
    return jsonEncode(_graph.toSummaryMap());
  }

  String? moveNode(String id, double x, double y){
    String? message = rules.checkMoveNode(_graph, id, x, y);
    if(message != null) return message;
    _pushHistory();
    _graph.moveNode(id, x, y);
    notifyListeners();
    return null;
  }

  String findNodeAt(double x, double y, {double minRadius = 0}) {
    return _graph.findNodeAt(x, y, minRadius: minRadius);
  }

  bool edgeExists(String sourceNode, String tap) {
    return _graph.edgeExists(sourceNode, tap);
  }

  void clearGraph(){
    _pushHistory();
    _graph.clear();
    _layoutVersion++;
    notifyListeners();
  }

   bool get canUndo => _history.isNotEmpty;

   bool get canRedo => _future.isNotEmpty;

   void _push(List<Graph> stack, Graph graph){
      stack.add(graph);
      if (stack.length > _maxHistory) {
        stack.removeAt(0);
      }
   }

   void _pushHistory(){
      _push(_history, _graph.clone());
      _future.clear();
   }

   void undo(){
     if (_history.isEmpty) return;
     _push(_future, _graph);
     _graph = _history.removeLast();
     notifyListeners();
   }

   void redo(){
     if (_future.isEmpty) return;
     _push(_history, _graph);
     _graph = _future.removeLast();
     notifyListeners();
   }

  Future<List<String>> listSavedGraphs() => _storage.listNames();

  Future<bool> savedGraphExists(String name) => _storage.exists(name);

  Future<void> saveGraph(String name) async {
   await _storage.save(name, _graph.toJson());
   _savedJson = _currentJson;
  }

  Future<String?> loadGraph(String name) async{
    final json = await _storage.load(name);
    if(json == null) return "Graph not found";
    Graph newGraph = Graph.fromJson(json);
    List<String> messages = rules.validateGraph(newGraph);
    if(messages.isNotEmpty) return messages.first;
    _pushHistory();
    _graph = newGraph;
    _savedJson = _currentJson;
    _layoutVersion++;
    notifyListeners();
    return null;
  }

  Future<void> deleteGraph(String name) async {
    await _storage.delete(name);
  }

}
